class Cmdb::ConfigurationsController < ApplicationController
  def show
    config = ::Configuration.find_by(_id: params[:id])
    if config.nil?
      render file: "public/404.html", status: :not_found
    else
      render plain: config.file
    end
  end
end
