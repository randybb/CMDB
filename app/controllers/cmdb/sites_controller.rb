class Cmdb::SitesController < ApplicationController
  def index
    orgid = params[:orgid]
    if orgid
      @sites = Site.where(org_id: orgid)
      @org_id = orgid
      @org_name = Organization.where(id: orgid).first
    else
      @sites = Site
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

  def show_dhcp_snooping
    site = Site.where(infra_id: params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.first
      @devices = Equipment.where(site_id: params[:id])
    end
  end

  def update_from_cmdb
    system "rake cmdb:update_sites org_id=#{params[:org_id]}"
    redirect_to action: 'index'
  end

  def update_from_devices
    devices = Equipment.where(site_id: params[:id])

    device_ids = []
    devices.each { |eq| device_ids << eq.id }

    system "rake device:default#{device_ids.to_s.gsub(' ', '')}"
    redirect_to :back
  end

  def create_project_files
    site = Site.where(infra_id: params[:id]).first
    s = site.cmdb

    system "rake -f ~/.rake/p.rake p:new_from_cmdb location=\"#{s[:country]}, #{s[:name]}\" site_id=#{site[:infra_id]}"
    redirect_to :back
  end
end
