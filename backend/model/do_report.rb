require 'csv'

class DOReport

  BASE_COLUMNS = [
    {:header => "Resource ID",          :proc => Proc.new {|resource, item| resource_id(resource)}},
    {:header => "Ref ID",               :proc => Proc.new {|resource, item| ref_id(item)}},
    {:header => "URI",                  :proc => Proc.new {|resource, item| record_uri(item)}},
    {:header => "Indicator 1",          :proc => Proc.new {|resource, item, box| indicator_1(box)}},
    {:header => "Indicator 2",          :proc => Proc.new {|resource, item, box| indicator_2(box)}},
    {:header => "Indicator 3",          :proc => Proc.new {|resource, item, box| indicator_3(box)}},
    {:header => "Title",                :proc => Proc.new {|resource, item| record_title(item)}},
    {:header => "Component ID",         :proc => Proc.new {|resource, item| component_id(item)}},
  ]

  SERIES_COLUMNS = [
    {:header => "Series",               :proc => Proc.new {|resource, item, box, series| record_title(series)}}
  ]

  SUBSERIES_COLUMNS = [
    {:header => "Sub-Series",           :proc => Proc.new {|resource, item, box, series, subseries| record_title(subseries)}}
  ]

  BARCODE_COLUMNS = [
    {:header => "Barcode",              :proc => Proc.new {|resource, item, box| barcode(box)}}
  ]

  DATES_COLUMNS = [
    {:header => "Dates",                :proc => Proc.new {|resource, item| dates(item)}}
  ]

  def initialize(rows, opts = {})
    @rows = rows
    @tsv = ''

    extras = allowed_extras.select { |e| opts.fetch(:extras) { [] }.include?(e) }

    @columns = BASE_COLUMNS

    extras.each do |extra|
      @columns += self.class.const_get(extra.upcase + '_COLUMNS')
    end

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
    @tsv = generate_line(@columns.map {|col| col[:header]})

    @rows.each do |row|
      add_row_to_report(row)
    end
  end


  def allowed_extras
    ['series', 'subseries', 'barcode', 'dates']
  end

  def empty_row
    {
      'resource' => {},
      'item' => {},
      'box' => {},
      'series' => {},
      'subseries' => {},
    }
  end


  def add_row_to_report(row)
    mrow = empty_row.merge(row)
    @tsv += generate_line(@columns.map {|col| col[:proc].call(mrow['resource']['_resolved'],
                                                              mrow['item'],
                                                              mrow['box'],
                                                              mrow['series']['_resolved'],
                                                              mrow['subseries']['_resolved'])})
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


  def self.ref_id(item)
    item['ref_id']
  end


  def self.indicator_1(box)
    if box['top_container']
      box['top_container']['_resolved']['indicator']
    end
  end


  def self.barcode(box)
    if box['top_container']
      box['top_container']['_resolved']['barcode']
    end
  end


  def self.indicator_2(box)
    box['indicator_2']
  end


  def self.indicator_3(box)
    box['indicator_3']
  end


  def self.component_id(item)
    item['component_id']
  end


  def self.dates(item)
    item['dates'].map { |date|
      dates = [date['begin'], date['end']].compact.join(' -- ')
      "#{date['label']}: #{dates}"
    }.join('; ')
  end

end
