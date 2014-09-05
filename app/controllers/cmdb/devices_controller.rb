class Cmdb::DevicesController < ApplicationController
  def index
    @devices = Equipment
  end

  def show
    device = Equipment.where(id: params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      @device = device.first
    end
  end

  def show_configuration
    device = Equipment.where(id: params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      configuration = device.file_configuration #.html_safe
      render plain: configuration
    end
  end

  def show_interfaces
    device = Equipment.where(id: params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      @device = device.first
    end
  end

  def show_cdp
    device = Equipment.where(id: params[:id])
    if device.nil?
      render file: "public/404.html", status: :not_found
    else
      @device_name = device.first.cmdb[:name]
      @device_cdp = device.first.device[:neighbors][:cdp]

      @device_cdp_neighbors = []
      @device_cdp.each do |device|
        device_name = device.hostname.downcase
        infr = Equipment.where(alias: device_name)
        # infr = CouchPotato.database.view(Equipment.find_by_alias(:key => device_name))
        infrid = ""
        infrid = infr[0][:_id] unless infr.nil? || infr.size != 1
        @device_cdp_neighbors << {device: device_name, infrid: infrid}
      end
      @device = device
    end
  end
end
