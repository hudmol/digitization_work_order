require 'csv'
require_relative 'id_generators/generator_interface'

class DOReport

  attr_reader :items

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
    {:header => "Series",               :proc => Proc.new { |resource, item, box, series|
                                                             series ? record_title(series) : ''
                                                          }}
  ]

  SUBSERIES_COLUMNS = [
    {:header => "Sub-Series",           :proc => Proc.new { |resource, item, box, series, subseries|
                                                             subseries ? record_title(subseries) : ''
                                                          }}
  ]

  BARCODE_COLUMNS = [
    {:header => "Barcode",              :proc => Proc.new {|resource, item, box| barcode(box)}}
  ]

  DATES_COLUMNS = [
    {:header => "Dates",                :proc => Proc.new {|resource, item| dates(item)}}
  ]


  def initialize(uris, opts = {})
    @uris = uris
    @generate_ids = opts[:generate_ids]

    if @generate_ids
      Dir.glob(base_dir("id_generators/*.rb")).each do |file|
        require(File.absolute_path(file))
      end

      generator_class = 'DefaultGenerator'
      if AppConfig.has_key?(:digitization_work_order_id_generator) 
        generator_class = AppConfig[:digitization_work_order_id_generator]
      end

      @id_generator = Kernel.const_get(generator_class).new
    end

    @columns = BASE_COLUMNS
    @extras = allowed_extras.select { |e| opts.fetch(:extras) { [] }.include?(e) }
    @extras.each do |extra|
      @columns += self.class.const_get(extra.upcase + '_COLUMNS')
    end

    build_items
  end


  def build(rows)
    @rows = rows

    build_report

    self
  end


  def to_stream
    StringIO.new(@tsv)
  end


  private


  def base_dir(path = nil)
    base = File.absolute_path(File.dirname(__FILE__))
    if path
      File.join(base, path)
    else
      base
    end
  end


  def build_items
    @items = []
    @uris.each do |uri|
      parsed = JSONModel.parse_reference(uri)

      # only archival_objects
      next unless parsed[:type] == "archival_object"

      ao = ArchivalObject[parsed[:id]]

      # only leaves
      next if ArchivalObject.where(:parent_id => ao[:id]).count > 0

      if @generate_ids && !ao.component_id
        ao = generate_id(ao)
      end

      item = {'item' => ArchivalObject.to_jsonmodel(ao)}
      item['resource'] = item['item']['resource']

      if @extras.include?('series') || @extras.include?('subseries')
        (series, subseries) = find_ancestors(ao)
        if series
          item['series'] = {'ref' => series.uri}
        end

        if subseries
          item['subseries'] = {'ref' => subseries.uri}
        end
      end

      item['item']['instances'].each do |instance|
        if instance['sub_container']
          item['box'] = instance['sub_container']
          break
        end
      end

      @items << item
    end
  end


  def generate_id(ao)
    ao[:component_id] = @id_generator.generate(ao)
    ao.save(:columns => [:component_id, :system_mtime])
    ao
  end


  def find_ancestors(ao)
    subseries = nil
    series = nil

    while true
      if ao[:parent_id].nil?
        break
      end
      ao = ArchivalObject[ao[:parent_id]]
      if ao.level == 'subseries'
        subseries = ao
      end
      if ao.level == 'series'
        series = ao
        break
      end
    end

    return series, subseries
  end


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
