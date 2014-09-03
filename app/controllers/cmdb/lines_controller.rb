class Cmdb::LinesController < ApplicationController
  def index
    @lines = CouchPotato.database.view(Line.all)
  end

  def show
    line = CouchPotato.database.load(params[:id])
    if line.nil?
      render file: "public/404.html", status: :not_found
    else
      @line = line.to_hash
    end
  end
end
