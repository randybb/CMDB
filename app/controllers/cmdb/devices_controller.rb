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
      configuration = device.first.file_config #.html_safe
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
      @device_name = device.first.name
      @device_id = device.first.id
      @device_cdp = device.first.device[:neighbors][:cdp]

      @device_cdp_neighbors = []
      @device_cdp.each do |device|
        device_name = device[:hostname].downcase
        infr = Equipment.where(alias: device_name)
        infrid = ""
        infrid = infr.first[:id] unless infr.nil?
        @device_cdp_neighbors << {device: device_name, infrid: infrid}
      end
      @device = device
    end
  end
end
