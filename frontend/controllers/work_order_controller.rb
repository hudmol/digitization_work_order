class WorkOrderController < ApplicationController

  set_access_control "view_repository" => [:index, :summary, :generate_report]

  def index
    @uri = params[:uri]
  end

  def summary
    @uris = params[:uri]

    render_aspace_partial :partial => "work_order/form"
  end

  def generate_report
    raise "Not implemented"
  end

end