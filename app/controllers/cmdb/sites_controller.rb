class Cmdb::SitesController < ApplicationController
  def index
    @sites = CouchPotato.database.view(Site.all)
  end

  def show
    site = CouchPotato.database.load(params[:id])
    if site.nil?
      render file: "public/404.html", status: :not_found
    else
      @site = site.to_hash
      @devices = CouchPotato.database.view(Equipment.for_sitid(:key => site._id.to_i))
    end
  end
end
