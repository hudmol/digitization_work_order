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

    rows = params[:uri].map do |uri|
      parsed = JSONModel.parse_reference(uri)

      # only archival_objects
      if parsed[:type] == "archival_object"
        ao = ArchivalObject[parsed[:id]]

        # only leaves
        if ArchivalObject.where(:parent_id => ao[:id]).count == 0
          pao = ao
          subseries = nil
          series = while true
                     if pao[:parent_id].nil?
                       break nil
                     end
                     pao = ArchivalObject[pao[:parent_id]]
                     if pao.level == 'subseries'
                       subseries = pao
                     end
                     if pao.level == 'series'
                       break pao
                     end
                   end

          row = {'item' => ArchivalObject.to_jsonmodel(ao)}
          if series
            row['series'] = {'ref' => series.uri}
          end

          if subseries
            row['subseries'] = {'ref' => subseries.uri}
          end

          row['resource'] = row['item']['resource']

          row['item']['instances'].each do |instance|
            if instance['sub_container']
              row['box'] = instance['sub_container']
              break
            end
          end

          resolve_references(row, resolve)
        end
      end
    end

    [
      200,
      {
        "Content-Type" => "text/tab-separated-values",
        "Content-Disposition" => "attachment; filename=\"digitization_work_order_report.tsv\""
      },
      DOReport.new(rows, opts).to_stream
    ]
  end

end
