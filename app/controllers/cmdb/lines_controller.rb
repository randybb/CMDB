class Cmdb::LinesController < ApplicationController
  def index
    @lines = Line
  end

  def show
    line = Line.where(id: params[:id])
    if line.nil?
      render file: "public/404.html", status: :not_found
    else
      @line = line.first
    end
  end
end
