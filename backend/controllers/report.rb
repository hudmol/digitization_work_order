class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/plugins/digitization_work_order/repositories/:repo_id/report')
  .description("Return TSV formatted report for record uris")
  .params(["repo_id", :repo_id],
          ["uri", [String], "The uris of the records to include in the report"],
          ["generate_ids", BooleanParam, "Whether to generate missing component_ids (defaults to false)", :optional => true],
          ["extras", [String], "Extra columns to include in the report", :optional => true])
  .permissions([:view_repository])
  .returns([200, "report"]) \
  do
    opts = {}
    opts[:extras] = params[:extras] || []
    opts[:generate_ids] = params[:generate_ids] || false

    [
      200,
      {
        "Content-Type" => "text/tab-separated-values",
        "Content-Disposition" => "attachment; filename=\"digitization_work_order_report.tsv\""
      },
      DOReport.new(params[:uri], opts).to_stream
    ]
  end


  # FIXME: make post only after dev'ing
  # FIXME add permission when done dev'ing # FIXME add permission when done dev'ing:
  #   .permissions([:view_repository])
  Endpoint.get_or_post('/plugins/digitization_work_order/repositories/:repo_id/ladybird')
    .description("Return Excel formatted export for record uris")
    .params(["repo_id", :repo_id],
            ["uri", [String], "The uris of the records to include in the report"])
    .permissions([])
    .returns([200, "report"]) \
  do
    [
      200,
      {
        "Content-Type" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "Content-Disposition" => "attachment; filename=\"#{ladybird_export_filename}\""
      },
      LadybirdExport.new(params[:uri]).to_stream
    ]
  end

  private

  def ladybird_export_filename
    'digitization_work_order_report.xlsx'
  end

end
