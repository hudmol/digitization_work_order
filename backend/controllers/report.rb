class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/plugins/digitization_work_order/repositories/:repo_id/report')
  .description("Return TSV formatted report for record uris")
  .params(["repo_id", :repo_id],
          ["uri", [String], "The uris of the records to include in the report"],
          ["extras", [String], "Extra columns to include in the report", :optional => true])
  .permissions([:view_repository])
  .returns([200, "report"]) \
  do
    opts = {}
    opts[:extras] = params[:extras] || []

    resolve = ['resource', 'top_container']

    resolve << 'series' if opts[:extras].include?('series')
    resolve << 'subseries' if opts[:extras].include?('subseries')

    report = DOReport.new(params[:uri], opts)

    [
      200,
      {
        "Content-Type" => "text/tab-separated-values",
        "Content-Disposition" => "attachment; filename=\"digitization_work_order_report.tsv\""
      },
      report.build(resolve_references(report.items, resolve)).to_stream
    ]
  end

end
