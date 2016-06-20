class WorkOrderController < ApplicationController

  set_access_control "view_repository" => [:summary, :generate_report]

  def summary
    @uris = params[:uri]

    render_aspace_partial :partial => "work_order/form"
  end

  def generate_report
    raise "Not implemented"
  end

end