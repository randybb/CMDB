class Cmdb::SitesController < ApplicationController
  def index
    @sites = Site
  end

  def show
    site = Site.where(infrid: params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.first
      @devices = Equipment.where(sitid: params[:id])
    end
  end
end
