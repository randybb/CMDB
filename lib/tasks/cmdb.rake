require 'csv'
require 'nokogiri'

#Moped::BSON = BSON

def get_records_from_cmdb(query_class, org_id)
  records_from = "1970-01-01" #TODO: move to a document in DB + add a document update after update of other documents is done

  uri_auth = {name: CMDB_WEB[:username], password: CMDB_WEB[:password]}
  uri = URI(CMDB_WEB[:uri] + CMDB_WEB[:"query_#{query_class}"] + "&owner_org_acr=#{org_id}")
  puts uri
  # uri = URI(CMDB_WEB[:uri] + CMDB_WEB[:"query_#{query_class}"] + "&changedafter=#{records_from}")

  record_class = Rack::Utils.parse_query(uri.query)['itype']
  #orgid = Rack::Utils.parse_query(uri.query)['owner_org_acr'] # now it is provided within request

  puts "== #{record_class.camelize}".colorize(:red)

  CSV::Converters[:blank_to_nil] = lambda do |field|
    field && field.empty? ? nil : field
  end

  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new uri
    request.basic_auth(uri_auth[:name], uri_auth[:password])

    t_start = Time.now
    response = http.request request
    t_stop = Time.now

    case response
      when Net::HTTPSuccess then
        # CSV PARSER
        #csv_data = CSV.new(response.body.force_encoding('ISO-8859-1').gsub("/n", "<br/>"), headers: true, header_converters: :symbol, converters: [:all, :blank_to_nil], col_sep: "\t", force_quotes: true)
        #data = csv_data.to_a.map { |row| row.to_hash }
        # HTML PARSER
        #html = File.open('cmdb.html', 'r').read
        html_data = Nokogiri::HTML(response.body.force_encoding('ISO-8859-1'))

        headers = []
        html_data.xpath('//*/table/tr')[0].xpath('td').each do |th|
          headers << th.text
        end

        data = []
        html_data.xpath('//*/table/tr')[1...-1].each_with_index do |row, i|
          data[i] = {}
          row.xpath('td').each_with_index do |td, j|
            data[i][headers[j]] = td.text
          end
        end

        # PARSER END
        data.each do |rec|
          record = rec.map{|(k,v)| [k.to_sym,v]}.to_h
          #CSV.parse(response.body.force_encoding('ISO-8859-1'), headers: true, header_converters: :symbol, converters: [:all, :blank_to_nil], col_sep: ";", force_quotes: true) do |record|
          puts "= #{record[:name]}".colorize(:yellow)
          infra_id = record[:infrid].to_i
          begin
            case record_class
              when 'Site' then
                infr = Site.find_or_create_by(infra_id: infra_id)
              when 'Equipment'
                infr = Equipment.find_or_create_by(infra_id: infra_id)
                infr.site_id = record[:sitid].to_i

                if !record[:alias_equipment] || record[:alias_equipment] == "" || record[:alias_equipment] == "none"
                  infr.alias = record[:name].gsub(".lan.skf.net", "").downcase
                else
                  infr.alias = record[:alias_equipment].downcase
                end
              when 'Line' then
                infr = Line.find_or_create_by(infra_id: infra_id)
              when 'Subnet' then
                infr = Subnet.find_or_create_by(infra_id: infra_id)
              when 'System' then
                infr = System.find_or_create_by(infra_id: infra_id)
              when 'Region' then
                infr = Region.find_or_create_by(infra_id: infra_id)
              when 'Solution' then
                infr = Solution.find_or_create_by(infra_id: infra_id)
              else
                raise "There is no record_class in query!"
            end
            infr.name = record[:name]
            infr.org_id = org_id.to_i
            infr.cmdb = record

            infr.save
            ap infr
          rescue Exception => e
            puts e.message
          end
        end

        cmdb_record = Infra.find_or_create_by(name: record_class)
        cmdb_record.updated_at = Time.now
        cmdb_record.save
      when Net::HTTPRedirection then
        puts "Redirected here!!!: " + response['location']
      else
        response.error!
    end
    puts "Query duration: #{t_stop - t_start}"
  end
end

namespace :cmdb do
  task :update => [:update_sites, :update_equipments]

  task :update_sites => :environment do |task, params|
    org_id = ENV['org_id']
    #params.extras.each do |org_id|
      get_records_from_cmdb("site", org_id)
    #end
  end

  task :update_equipments => :environment do |task, params|
    org_id = ENV['org_id']
    #params.extras.each do |org_id|
      get_records_from_cmdb("equipment", org_id)
    #end
  end
end
