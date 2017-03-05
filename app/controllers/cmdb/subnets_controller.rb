class Cmdb::SubnetsController < ApplicationController
  def index
    @subnets = SUbnet
  end

  def show
    subnet = Subnet.where(infra_id: params[:id])
    if subnet.nil?
      render file: "public/404.html", status: :not_found
    else
      @subnet = subnet.first
    end
  end
end
