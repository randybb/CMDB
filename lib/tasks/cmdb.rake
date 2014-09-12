require 'csv'

def get_records_from_cmdb(query_class)
  records_from = "1970-01-01" #TODO: move to a document in DB + add a document update after update of other documents is done

  uri_auth = {name: CMDB_WEB[:username], password: CMDB_WEB[:password]}
  uri = URI(CMDB_WEB[:uri] + CMDB_WEB[:"query_#{query_class}"])
  # uri = URI.join(CMDB_WEB[:uri], CMDB_WEB[:"query_#{query_class}"], "&changedafter=#{records_from}")

  record_class = Rack::Utils.parse_query(uri.query)['itype']
  orgid = Rack::Utils.parse_query(uri.query)['owner_org_acr']

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
        csv_data = CSV.new(response.body.force_encoding('ISO-8859-1'), headers: true, header_converters: :symbol, converters: [:all, :blank_to_nil], col_sep: ";", force_quotes: true)
        data = csv_data.to_a.map { |row| row.to_hash }
        data[0...-1].each do |record|
          puts "= #{record[:name]}".colorize(:yellow)
          begin
            case record_class
              when 'Site' then
                infr = Site.find_or_create_by(id: record[:infrid])
              when 'Equipment'
                infr = Equipment.find_or_create_by(id: record[:infrid])
                infr.site_id = record[:sitid]

                if (!record[:alias_equipment] || record[:alias_equipment] == "" || record[:alias_equipment] == "none")
                  infr.alias = record[:name].gsub(".lan.skf.net", "").downcase
                else
                  infr.alias = record[:alias_equipment].downcase
                end
              when 'Line' then
                infr = Line.find_or_create_by(id: record[:infrid])
              when 'Subnet' then
                infr = Subnet.find_or_create_by(id: record[:infrid])
              when 'System' then
                infr = System.find_or_create_by(id: record[:infrid])
              when 'Region' then
                infr = Region.find_or_create_by(id: record[:infrid])
              when 'Solution' then
                infr = Solution.find_or_create_by(id: record[:infrid])
              else
                raise "There is no record_class in query!"
            end
            infr.name = record[:name]
            infr.org_id = orgid.to_i
            infr.cmdb = record

            infr.save
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

namespace :cmdb do
  task :update => [:update_sites, :update_equipments]

  task :update_sites => :environment do
    get_records_from_cmdb("site")
  end

  task :update_equipments => :environment do
    get_records_from_cmdb("equipment")
  end
end