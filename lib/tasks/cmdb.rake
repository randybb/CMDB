require 'csv'

def get_records_from_cmdb(query_class)
  records_from = "1970-01-01" #TODO: move to a document in DB + add a document update after update of other documents is done

  uri_auth = {name: CMDB_WEB[:username], password: CMDB_WEB[:password]}
  uri = URI.join(CMDB_WEB[:uri], CMDB_WEB[:"query_#{query_class}"], "&changedafter=#{records_from}")

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
        csv_data = CSV.new(response.body.force_encoding('ISO-8859-1'), headers: true, header_converters: :symbol, converters: :all, col_sep: ";", force_quotes: true)
        data = csv_data.to_a.to_a.map { |row| row.to_hash }
        data[0...-1].each do |record|
          puts "= #{record[:name]}".colorize(:yellow)
          begin
            existing_infr = CouchPotato.database.load(params[:id])
            if existing_infr.nil?
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

              infr._id = record[:infrid].to_s
            else
              infr = existing_infr
            end
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

namespace :cmdb do
  task :update => [:update_sites, :update_equipments]

  task :update_sites => :environment do
    get_records_from_cmdb("site")
  end

  task :update_equipments => :environment do
    get_records_from_cmdb("equipmnet")
  end
end