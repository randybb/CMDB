@device_ids = [7357596,
               7357598,
               7357600,
               7357602,
               7357605,
               7357606,
               7357609,
               7357610,
               7437051]

def clogin(ip_address, filename)
  `clogin -x ~/.clogin/show #{ip_address} | tee #{filename}`
end

##
# next functions are required for the configuration parser

# TODO: change to the real location
ICON = {
    firewall_asa: 'cisco_shapes/firewall_asa.png',
    firewall: 'cisco_shapes/firewall.png',
    router_fw: 'cisco_shapes/router_fw.png',
    router: 'cisco_shapes/router.png',
    router_switch_fwsm: 'cisco_shapes/router_switch_fwsm.png',
    router_switch: 'cisco_shapes/router_switch.png',
    router_switch_vss: 'cisco_shapes/router_switch_vss.png',
    switch_dc: 'cisco_shapes/switch_dc.png',
    switch_l2: 'cisco_shapes/switch_l2.png',
    switch_l2_stack: 'cisco_shapes/switch_l2_stack.png',
    switch_l3: 'cisco_shapes/switch_l3.png',
    switch_l3_stack: 'cisco_shapes/switch_l3_stack.png',
    wlan_ap_dual: 'cisco_shapes/wlan_ap_dual.png',
    wlan_ap_lwap: 'cisco_shapes/wlan_ap_lwap.png',
    wlan_ap: 'cisco_shapes/wlan_ap.png',
    wlan_controller: 'cisco_shapes/wlan_controller.png',
}

def ipv4_a_to_s(array)
  output = ""
  array.each do |line|
    begin
      cidr = NetAddr::CIDR.create "#{line[:address]} #{line[:mask]}"
      output += cidr.to_s + " "
    rescue
      nil
    end
  end unless array.nil?
  return output.strip
end

namespace :device do
  desc 'Run show commands on a device and store it to Equipment.file_config'
  task :get_configuration => :environment do
    puts "== Downloading configurations"
    @device_ids.each do |device_id|
      device = Equipment.where(id: device_id).first

      puts "= #{device.name} (#{device.id})"
      if device.cmdb[:up] == 0
        created_at = DateTime.now.utc.to_s
        temp_file = "tmp/#{device[:name]}.txt"

        device.timestamps = {} if device.timestamps.nil?

        clogin(device.cmdb[:real_ip], temp_file)

        device_configuration = File.read(temp_file)
        device.file_config = device_configuration

        device.timestamps[:configuration] = created_at
        device.save
        puts "OK"
        File.delete temp_file
      else
        puts "is a slave device for #{device.cmdb[:up_value]}!"
      end
    end
  end

  desc 'Parse Equipment.file_config and store its output output to Equipment.device'
  task :parse_configuration => :environment do
    puts "== Parsing configurations"
    @device_ids.each do |device_id|
      device = Equipment.where(id: device_id).first

      puts "= #{device.name} (#{device.id})"
      if device.cmdb[:up] == 0 && !device.file_config.nil?
        created_at = DateTime.now.utc.to_s

        device.device = {} if device.device.nil?
        device.device[:neighbors] = {} if device.device[:neighbors].nil?
        device.timestamps = {} if device.timestamps.nil?

        device_config = device.file_config.gsub!(/(\r|\n)+/, "\n")

        # TODO: add condition based on device type: Switch/Router and WLC
        parsed_device_config = CiscoParser::IOS.new device_config

        parsed_hostname = parsed_device_config.hostname
        parsed_interfaces = parsed_device_config.show_interfaces
        parsed_cdp = parsed_device_config.show_cdp

        device.device[:hostname] = parsed_hostname
        device.device[:interfaces] = parsed_interfaces
        device.device[:neighbors][:cdp] = parsed_cdp
        device.timestamps[:parsed_configuration] = created_at
        device.save
        puts "OK"
      else
        puts "is a slave device for #{device.cmdb[:up_value]}!" if device.cmdb[:up] > 0
        puts "it doesn't contains the configuration attachment!" if device._attachments["configuration"].nil
      end
    end
  end
end
