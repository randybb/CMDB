# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
=begin
require 'csv'

# bugs: https://redmine.tools.emea.hp.com/projects/r2
# api: http://r2.grenoble.hp.com/doc/3/Tip39
# http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Equipment&name=itbar&fields=infrid,name,IP,real_IP&format=html

def get_records_from_cmdb(uri)
  uri_auth = {name: CMDB_WEB[:username], password: CMDB_WEB[:password]}
  record_class = Rack::Utils.parse_query(uri.query)['itype']
  orgid = Rack::Utils.parse_query(uri.query)['owner_org_acr']

  puts "== #{record_class.camelize}".colorize(:red)
  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new uri
    request.basic_auth(uri_auth[:name], uri_auth[:password])

    t_start = Time.now
    response = http.request request
    t_stop = Time.now

    case response
      when Net::HTTPSuccess then
        csv_data = CSV.new(response.body.force_encoding('ISO-8859-1'), headers: true, header_converters: :symbol, converters: :all, col_sep: ";")
        data = csv_data.to_a.to_a.map { |row| row.to_hash }
        data[0...-1].each do |record|
          puts "= #{record[:name]}".colorize(:yellow)
          case record_class
            when 'Site' then
              infr = Site.new
            when 'Equipment'
              infr = Equipment.new
            when 'Line' then
              infr = Line.new
            when 'Subnet' then
              infr = Subnet.new
            when 'System' then
              infr = System.new
            when 'Region' then
              infr = Region.new
            when 'Solution' then
              infr = Solution.new
            else
              raise "There is no record_class in query!"
          end

          begin
            infr._id = record[:infrid].to_s
            infr.name = record[:name]
            infr.orgid = orgid.to_i
            infr.cmdb = record
            CouchPotato.database.save_document infr
          rescue Exception => e
            puts e.message
          end
        end
      when Net::HTTPRedirection then
        puts "here: " + response['location']
      else
        response.error!
    end
    puts "Query duration: #{t_stop - t_start}"
  end
end

uri_site = URI.parse("http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Site&owner_org_acr=88&fields=infrid,name,up_value,alias,type,site_acro,region,region_value,country,the_state,city,zip_code,address,timezone,empl_nb,open_hours,step,owner_org_value,business_group,business_category,ovsd_search_code,creationdate,lastchangedate,first_mtp_date,last_obsolete_date")
uri_equipment = URI.parse("http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Equipment&owner_org_acr=88&fields=infrid,name,up,up_value,IP,IP_mask,real_IP,real_IP_mask,default_gw,alias_equipment,peerid,sitid,sitid_value,floor,region,region_value,criticality,impact,service_type,category,type,description,brand,model_nb,complexity,sys_object_id,part_nb,serial_nb,asset_owner,asset_id,sys_handle,maintenance,order_nb,nb_ports,os_version,hw_version,memory,mac_addr,snmp_get_,snmp_set_,snmp_v3_,first_level_pwd_,second_level_pwd_,step,owner_org_value,business_group,business_category,billed_location,comment,ovsd_search_code,creationdate,lastchangedate,first_mtp_date,last_obsolete_date")
uri_line = URI.parse("http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Line&owner_org_acr=88&fields=infrid,name,type,sitid1,sitid1_value,sitid2,sitid2_value,region,region_value,criticality,impact,capacity_num,capacity,acro_prov1_value,ref_site1,acro_prov2_value,ref_site2,used_for,cost_monthly,cost_currency,cost_comment,ordering_info,delivery_date,renewal_date,cancellation_date,step,up,up_value,up2,up2_value,owner_org_value,business_group,business_category,creationdate,lastchangedate,first_mtp_date,last_obsolete_date")
uri_subnet = URI.parse("http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Subnet&owner_org_acr=88&fields=infrid,name,mask,type,description,lineid,lineid_value,sitid,sitid_value,region,region_value,step,owner_org_value,business_group,business_category,creationdate,lastchangedate,first_mtp_date,last_obsolete_date")

# uri = URI.parse("http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Equipment&owner_org_acr=88&changedafter=2014-08-27")

get_records_from_cmdb(uri_site)
get_records_from_cmdb(uri_equipment)
get_records_from_cmdb(uri_subnet)

# devices = CouchPotato.database.view(Equipment.all)
# devices.each do |device|
#   deviceid = device["_id"]
#   puts "=== on #{device[:cmdb][:name]}".colorize(:red)
#   uri_interface = URI.parse("http://r2.grenoble.hp.com/r2_admin/list_infra/?itype=Interface&owner_org_acr=88&deviceid=#{deviceid}&fields=infrid,name,ifcanonicalname,deviceid,deviceid_value,IP,IP_mask,real_IP,real_IP_mask,NAT_IP,type,criticality,impact,connectid,lineid,lineid_value,duplex_config,capacity_num,snmp_type,ifindex,acl_in,acl_out,model_nb,part_nb,mac_addr,first_level_pwd_,step,owner_org_value,business_group,business_category,creationdate,lastchangedate,first_mtp_date,last_obsolete_date")
#   get_records_from_cmdb(uri_interface, cmdb_uri_auth, "Interface", db, db_name)
# end

# get_records_from_cmdb(uri_line)
# get_records_from_cmdb(uri_system)
# get_records_from_cmdb(uri_region)
# get_records_from_cmdb(uri_solution)
=end
