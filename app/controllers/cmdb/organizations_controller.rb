class Cmdb::OrganizationsController < ApplicationController
  def index
    @orgs = Organization.order_by(name: 'asc')
  end

  def show
    # site = Site.where(id: params[:id])
    # if site.nil?
    #   render file: "public/404.html", status: :not_found
    # else
    #   @site = site.first
    #   @devices = Equipment.where(site_id: params[:id])
    # end
  end
end
