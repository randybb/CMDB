class Cmdb::InterfacesController < ApplicationController
  def index
    @interfaces = Interface
  end

  def show
    interface = Interface.where(infra_id: params[:id])
    if interface.nil?
      render file: "public/404.html", status: :not_found
    else
      @interface = interface.first
    end
  end
end
