class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/plugins/digitization_work_order/repositories/:repo_id/report')
  .description("Return TSV formatted report for record uris")
  .params(["repo_id", :repo_id],
          ["uri", [String], "The uris of the records to include in the report"])
  .permissions([:view_repository])
  .returns([200, "report"]) \
  do

    rows = params[:uri].map do |uri|
      parsed = JSONModel.parse_reference(uri)
      if parsed[:type] == "archival_object"
        resolve_references(ArchivalObject.to_jsonmodel(ArchivalObject.get_or_die(parsed[:id])), ["resource", "top_container"])
      end
    end

    [
      200,
      {
        "Content-Type" => "text/tab-separated-values",
        "Content-Disposition" => "attachment; filename=\"digitization_work_order_report.tsv\""
      },
      DOReport.new(rows).to_stream
    ]
  end

end
