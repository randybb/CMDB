class Cmdb::InterfacesController < ApplicationController
  def index
    @interfaces = CouchPotato.database.view(Interface.all)
  end

  def show
    interface = CouchPotato.database.load(params[:id])
    if interface.nil?
      render file: "public/404.html", status: :not_found
    else
      @interface = interface.to_hash
    end
  end
end
