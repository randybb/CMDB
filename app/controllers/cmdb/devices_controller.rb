class Cmdb::DevicesController < ApplicationController
  def index
    @devices = CouchPotato.database.view(Equipment.all)
  end

  def show
    device = CouchPotato.database.load(params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      @device = device
    end
  end

  def show_configuration
    device = CouchPotato.database.load(params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      configuration = CouchPotato.couchrest_database.fetch_attachment(device[:_id], "configuration") #.html_safe
      render plain: configuration
    end
  end

  def show_interfaces
    device = CouchPotato.database.load(params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      @device = device
    end
  end

  def show_cdp
    device = CouchPotato.database.load(params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      @device_name = device[:cmdb][:name]
      @device_cdp = device[:device][:neighbors][:cdp]

      @device_cdp_neighbors = []
      @device_cdp.each do |device|
        device_name = device[:hostname].downcase
        infr = CouchPotato.database.view(Equipment.find_by_alias(:key => device_name))
        infrid = ""
        infrid = infr[0][:_id] unless infr.nil? || infr.size != 1
        @device_cdp_neighbors << {device: device_name, infrid: infrid}
      end
      @device = device
    end
  end
end
