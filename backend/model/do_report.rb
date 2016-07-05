require 'csv'

class DOReport

  COLUMNS = [
    {:header => "Resource ID",          :proc => Proc.new {|resource, ao| resource_id(resource)}},
    {:header => "Ref ID",               :proc => Proc.new {|resource, ao| ref_id(ao)}},
    {:header => "URI",                  :proc => Proc.new {|resource, ao| record_uri(ao)}},
  ]


  def initialize(rows)
    @rows = rows
    @tsv = ''

    build_report
  end

  def to_stream
#    @tsv.to_stream
    @tsv
  end

  private

  def generate_line(data)
    CSV.generate_line(data, :col_sep => "\t")
  end

  def build_report
    @tsv = generate_line(COLUMNS.map {|col| col[:header]})

    @rows.each do |row|
      add_row_to_report(row)
    end
  end


  def add_row_to_report(row)
    @tsv += generate_line(COLUMNS.map {|col| col[:proc].call(row["resource"]["_resolved"], row)})
  end


  # Cell value generators
  def self.record_uri(record)
    record['uri']
  end


  def self.record_title(record)
    record['title']
  end


  def self.resource_id(resource)
    (0..3).map {|i| resource["id_#{i}"]}.compact.join(".")
  end


  def self.ref_id(ao)
    ao['ref_id']
  end

end
