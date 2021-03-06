def clogin(ip_address, filename)
  `clogin -x ~/.clogin/show #{ip_address} | tee #{filename}`
end

def hlogin(hostname, filename)
  `ssh idajmpl01 "./hlogin-new #{hostname}" | sed "s/\r//g" | tee #{filename}`
end

namespace :device do
  desc "Get and Parse"
  task :default => [:get_configuration]
  #task :default => [:get_configuration, :parse_configuration]

  desc 'Run show commands on a device and store it to Configurations (with relation)'
  task :get_configuration => :environment do |task, params|
    puts "== Downloading configurations"
    params.extras.each do |device_id|
      device = Equipment.where(infra_id: device_id).first

      puts "= #{device.name} (#{device.infra_id})"
      # Cisco devices
      if device.cmdb[:up] == 0 && device.cmdb[:brand] == 'Cisco' && device.cmdb[:type] == 'Switch' && device.cmdb[:step] == 'production'
        temp_file = "tmp/#{device[:name]}.txt"

        clogin(device.cmdb[:real_ip], temp_file)

        device.configurations.create(infra_id: device.infra_id, file: File.read(temp_file))
        puts "OK"
        File.delete temp_file
      # HP/Aruba devices, or simplier "not Cisco"
      elsif (%w[Aruba HP HPE].include? device.cmdb[:brand]) && (device.cmdb[:type] == 'Switch' || device.cmdb[:type] == 'Routing Switch') && device.cmdb[:step] == 'production'
        temp_file = "tmp/#{device[:name]}.txt"

        hlogin(device.cmdb[:name], temp_file)

        device.configurations.create(infra_id: device.infra_id, file: File.read(temp_file))
        puts "OK"
        File.delete temp_file
	  # and other devices
      else
        puts "is a slave device for #{device.cmdb[:up_value]}!" unless device.cmdb[:up_value].empty?
		puts "#{device.cmdb[:brand]} / #{device.cmdb[:type]} / #{device.cmdb[:step]}"
      end
    end
  end

  desc 'Parse Equipment.last_configuration.file and store its output output to Equipment.device'
  task :parse_configuration => :environment do |task, params|
    puts "== Parsing configurations"
    params.extras.each do |device_id|
      begin
      device = Equipment.where(id: device_id).first

      puts "= #{device.name} (#{device.id})"
      if device.cmdb[:up] == 0 && !device.last_configuration.nil? && device.cmdb[:brand] == 'Cisco' && device.cmdb[:type] == 'Switch'
        created_at = DateTime.now.utc.to_s

        device.device = {} if device.device.nil?
        device.device[:neighbors] = {} if device.device[:neighbors].nil?
        device.timestamps = {} if device.timestamps.nil?

        device_config = device.last_configuration.file.gsub!(/(\r|\n)+/, "\n")

        # TODO: add condition based on device type: Switch/Router and WLC
        parsed_device_config = CiscoParser::IOS.new device_config

        parsed_hostname = parsed_device_config.hostname
        parsed_interfaces = parsed_device_config.show_interfaces
        parsed_cdp = parsed_device_config.show_cdp
        parsed_pos = parsed_device_config.show_etherchannels

        device_cdp_neighbors = []
        parsed_cdp.each do |device|
          po = parsed_pos.find do |po|
            po[:ports].find do |port|
              port[:name] == device[:src_interface_abbr]
            end
          end
          po.nil? ? src_interface_po = nil : src_interface_po = po[:name]
          device_cdp_neighbors << device.merge(src_interface_po: src_interface_po)
        end

        device.device[:hostname] = parsed_hostname
        device.device[:interfaces] = parsed_interfaces
        device.device[:neighbors][:cdp] = device_cdp_neighbors
        device.timestamps[:parsed_configuration] = created_at
        device.save
        puts "OK"
      else
        puts "is a slave device for #{device.cmdb[:up_value]}!" if device.cmdb[:up] > 0
        puts "it doesn't contains the configuration attachment!" if device._attachments["configuration"].nil
      end
      rescue
        nil
      end
    end
  end
end
