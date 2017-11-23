class Cmdb::SitesController < ApplicationController
  def index
    orgid = params[:orgid]
    if orgid
      @sites = Site.where(org_id: orgid).order_by(name: 'asc')
      @org_id = orgid
      @org_name = Organization.where(id: orgid).first
    else
      @sites = Site.order_by(name: 'asc')
      @org_id = orgid
      @org_name = nil
    end
    infra = Infra.where(name: 'Site').first
    if infra.nil?
      @cmdb_ver = nil
    else
      @cmdb_ver = infra.updated_at.to_s(:custom_short)
    end
  end

  def show
    site = Site.where(infra_id: params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.first
      @devices = Equipment.where(site_id: params[:id])
    end
  end
	
	def show_cmdb_export
		csv_mapping = {
			name: "name",
		  up_value: "parent equipment", # based on peerid
			IP: "management IP",
			IP_mask: "management IP mask",
			real_IP: "real IP address",
			real_IP_mask: "real IP mask",
			default_gw: "default gateway",
			alias: "alias",
		#	: "high availability peer",
			sitid_value: "site",
			floor: "building-floor-room-tile",
			region_value: "region/group",
			criticality: "criticality",
			impact: "customer impact",
			service_type: "service type",
			category: "category",
			type: "type",
			description: "function/role",
			brand: "brand",
			model_nb: "model",
		#	: "vendor end of support",
			complexity: "complexity",
			sys_object_id: "sys object id",
			part_nb: "part number",
			serial_nb: "serial number",
		#	: "detected serial number",
		#	: "difference on serial number",
		#	: "serial number comment",
			asset_owner: "asset owner", # Customer / Leased??
			asset_id: "asset identifier",
			sys_handle: "system handle", # Project name
			maintenance: "maintenance window",
			order_nb: "sales order nb", # billed price
			nb_ports: "number of ports/capacity",
			os_version: "SW version",
		#	: "active blockpoint versions",
		#	: "obsolete blockpoint versions",
			hw_version: "HW version",
			memory: "memory",
			mac_addr: "mac address",
			step: "step",
			owner_org_value: "owner organization",
			business_group: "business group",
			business_category: "business category",
			business_code: "business code",
			business_type: "business type",
			billed_location: "billed location",
			comment: "comment",
		#	: "unified code",
		#	: "creation date",
		#	: "last change date",
		#	: "move to prod date",
		#	: "obsolescence date"
		}
				
    site = Site.where(infra_id: params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.first
      @devices = Equipment.where(site_id: params[:id]).order_by(name: 'asc')
    end
		
		csv_output = CSV.generate(headers: true) do |csv|
			csv << csv_mapping.values
			@devices.each do |device|
			d = device[:cmdb]
				if ((d[:step] == "production") && (d[:type] == "Switch"))
					csv << csv_mapping.map{ |key, value| d[key] }
					unless device.file_config.nil?
						# this needs to be moved to device.rake
						device_config = device.file_config.gsub!(/(\r|\n)+/, "\n")
						parsed_device_config = CiscoParser::AOSSW.new device_config
						
						hostname = parsed_device_config.hostname
						stack = parsed_device_config.show_stacking
						transceivers = parsed_device_config.show_transceivers
						modules = parsed_device_config.show_modules
						
						# name-1.wartsila.com
						stack.drop(1).each do |i|
							ch = d.clone
							ch[:name] = "#{hostname}-#{i[:id]}.wartsila.com"
							ch[:up] = d[:name]
							ch[:description] = "Switch Member"
							ch[:mac_addr] = i[:mac_address]
							ch[:part_nb] = i[:part_number]
							ch[:model_nb] = i[:model].gsub(/#{i[:part_number]} /, "")
							ch[:serial_nb] = "" # show system
							ch[:os_version] = ""
							ch[:memory] = ""
# 						  ap ch
							csv << csv_mapping.map{ |key, value| ch[key] }
						end
						# name_gbic45
						transceivers.each do |i|
						  m = {}
							m[:name] = "#{hostname}_gbic#{i[:port].gsub("/", "_")}"
							m[:up_value] = d[:name]
							m[:IP] = ""
							m[:IP_mask] = ""
							m[:real_IP] = ""
							m[:real_IP_mask] = ""
							m[:default_gw] = ""
							m[:alias_equipment] = ""
							m[:peerid] = "0"
							m[:sitid_value] = d[:sitid_value]
							m[:floor] = "Switch"
							m[:region] = d[:region]
							m[:region_value] = d[:region_value]
							m[:criticality] = d[:criticality]
							m[:impact] = "Please look for special handling instruction in R2 general page."
							m[:service_type] = "LAN"
							m[:category] = "hardware"
							m[:type] = "Module"
							m[:description] = ""
							m[:brand] = "HP"
							m[:model_nb] = i[:type]
							m[:complexity] = ""
							m[:sys_object_id] = ""
							m[:part_nb] = i[:part_number]
							m[:serial_nb] = ""
							m[:asset_owner] = "Customer"
							m[:asset_id] = ""
							m[:sys_handle] = ""
							m[:maintenance] = ""
							m[:order_nb] = ""
							m[:step] = "Implementation"
							m[:owner_org_value] = "Wartsila"
# 							ap m
							csv << csv_mapping.map{ |key, value| m[key] }
						end
						
# 						csv << ""
						# name_stack1
						modules.each do |i|
						  m = {}
							m[:name] = "#{hostname}_stack#{i[:id]}"
							m[:up_value] = d[:name]
							m[:IP] = ""
							m[:IP_mask] = ""
							m[:real_IP] = ""
							m[:real_IP_mask] = ""
							m[:default_gw] = ""
							m[:alias_equipment] = ""
							m[:peerid] = "0"
							m[:sitid_value] = d[:sitid_value]
							m[:floor] = "Switch"
							m[:region] = d[:region]
							m[:region_value] = d[:region_value]
							m[:criticality] = d[:criticality]
							m[:impact] = "Please look for special handling instruction in R2 general page."
							m[:service_type] = "LAN"
							m[:category] = "hardware"
							m[:type] = "Module"
							m[:description] = ""
							m[:brand] = "HP"
							m[:model_nb] = i[:description] # needs to be converted "HP J9733A 2-port Stacking Module" -> "HP 2920 2-port Stacking Module"
							m[:complexity] = ""
							m[:sys_object_id] = ""
							m[:part_nb] = i[:part_number]
							m[:serial_nb] = i[:serial_number]
							m[:asset_owner] = "Customer"
							m[:asset_id] = ""
							m[:sys_handle] = ""
							m[:maintenance] = ""
							m[:order_nb] = ""
							m[:step] = "Implementation"
							m[:owner_org_value] = "Wartsila"
# 							ap m
							csv << csv_mapping.map{ |key, value| m[key] }
						end
						
					end
				end
			end
		end

		send_data csv_output, :filename => 'cmdb_import.csv'
  end

  def show_dhcp_snooping
    site = Site.where(infra_id: params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.first
      @devices = Equipment.where(site_id: params[:id]).order_by(name: 'asc')
    end
  end

  def update_from_cmdb
    system "rake cmdb:update_sites org_id=#{params[:org_id]}"
    redirect_to action: 'index'
  end

  def update_from_devices
    devices = Equipment.where(site_id: params[:id])

    device_ids = []
    devices.each { |eq| device_ids << eq.infra_id }

    system "rake device:default#{device_ids.to_s.gsub(' ', '')}"
    redirect_back(fallback_location: cmdb_sites_path)
  end

  def create_project_files
    site = Site.where(infra_id: params[:id]).first
    s = site.cmdb

    system "rake -f ~/.rake/p.rake p:new_from_cmdb location=\"#{s[:country]}, #{s[:name]}\" site_id=#{site[:infra_id]}"
    redirect_back(fallback_location: cmdb_sites_path)
  end
end
