require 'csv'

class DOReport

  COLUMNS = [
    {:header => "Resource ID",          :proc => Proc.new {|resource, ao| resource_id(resource)}},
    {:header => "Ref ID",               :proc => Proc.new {|resource, ao| ref_id(ao)}},
    {:header => "URI",                  :proc => Proc.new {|resource, ao| record_uri(ao)}},
    {:header => "Indicator 1",          :proc => Proc.new {|resource, ao, box| indicator_1(box)}},
    {:header => "Indicator 2",          :proc => Proc.new {|resource, ao, box| indicator_2(box)}},
    {:header => "Indicator 3",          :proc => Proc.new {|resource, ao, box| indicator_3(box)}},
    {:header => "Title",                :proc => Proc.new {|resource, ao| record_title(ao)}},
    {:header => "Component ID",         :proc => Proc.new {|resource, ao| component_id(ao)}},
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
    @tsv += generate_line(COLUMNS.map {|col| col[:proc].call(row["resource"]["_resolved"], row, row["instances"][0]["sub_container"])})
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


  def self.indicator_1(box)
    box['top_container']['_resolved']['indicator']
  end


  def self.indicator_2(box)
    box['indicator_2']
  end


  def self.indicator_3(box)
    box['indicator_3']
  end


  def self.component_id(ao)
    ao['component_id']
  end

end
