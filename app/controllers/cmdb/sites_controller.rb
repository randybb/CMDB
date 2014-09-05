class Cmdb::SitesController < ApplicationController
  def index
    @sites = Site
  end

  def show
    site = Site.where(id: params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.first
      @devices = Equipment.where(site_id: params[:id])
    end
  end
end
