class Cmdb::SubnetsController < ApplicationController
  def index
    @subnets = CouchPotato.database.view(Subnet.all)
  end

  def show
    subnet = CouchPotato.database.load(params[:id])
    if subnet.nil?
      render file: "public/404.html", status: :not_found
    else
      @subnet = subnet.to_hash
    end
  end
end
