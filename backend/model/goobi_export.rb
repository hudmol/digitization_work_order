require 'write_xlsx'

class GoobiExport

  NEW_LINE_SEPARATOR = ' | '

  def initialize(uris, resource_uri)
    @uris = uris
    @resource_uri = resource_uri
    @ids = extract_ids

    parsed_resource_uri = JSONModel.parse_reference(@resource_uri)
    @resource_id = parsed_resource_uri.fetch(:id)
    parsed_repo_uri = JSONModel.parse_reference(parsed_resource_uri.fetch(:repository))
    @repo_id = parsed_repo_uri.fetch(:id)
  end

  def column_definitions
    [
      # Local record ID {fdid=57}
      {:header => "aspace_uri",              :proc => Proc.new {|row| local_record_id(row)}}, # NEW ish -- was 56 but needed to be moved to 57
      # Call number {fdid=58}
      {:header => "callNumber",             :proc => Proc.new {|row| call_number(row)}},
      # Box {fdid=60}
      {:header => "container(Box)",         :proc => Proc.new {|row| box(row)}},
      # Folder {fdid=61}
      {:header => "subcontainer(Folder)",   :proc => Proc.new {|row| folder(row)}},
      # Host, Title {fdid=63}
      {:header => "hostTitle",              :proc => Proc.new {|row| host_title(row)}},
      # Dates Inclusive/Bulk {fdid=66}
      {:header => "dates",                  :proc => Proc.new {|row| collection_creation_years(row)}},
      # Host, note {fdid=68}
      {:header => "sourceNote",           :proc => Proc.new {|row| host_note(row)}},
      # Title {fdid=70}
      {:header => "title",                  :proc => Proc.new {|row| title(row)}},
      # Physical description {fdid=82}
      {:header => "physDesc",               :proc => Proc.new {|row| physical_description(row)}},
      # Note {fdid=86}
      {:header => "note",              :proc => Proc.new {|row| note(row)}},
      # Abstract {fdid=87}
      {:header => "abstract",               :proc => Proc.new {|row| abstract(row)}},
      # Barcode {fdid=105}
      {:header => "aspace_barcode",                :proc => Proc.new {|row| barcode(row)}},
      # Publication Type
      {:header => "pubType",                :proc => Proc.new {|row| "ArchivalObject" }},
      # Collection
      {:header => "collection",             :proc => Proc.new {|row| "DefaultCollection" }},
      # use opac
      {:header => "useOPAC",                :proc => Proc.new {|row| "TRUE" }},
      # use aspace opac
      {:header => "opacName",               :proc => Proc.new {|row| "aspace" }},
      #Process title
      {:header => "processTitle",           :proc => Proc.new {|row| nil }}, #BLANK!
    ]
  end

  def to_stream
    io = StringIO.new
    wb = WriteXLSX.new(io)

    sheet = wb.add_worksheet('Digitization Work Order')

    hl_color = wb.set_custom_color(15, '#E8F4FF')
    highlight = wb.add_format(:bg_color => 15)

    row_ix = 0
    sheet.write_row(row_ix, 0, column_definitions.collect{|col| col.fetch(:header)})

    # PLEASE NOTE
    # `dataset` hits the database to return all the instance rows but it also
    # fire a series of extra queries from which we aggregate all multi-valued
    # fields required for the report. These values are stored as instance
    # variables and as such many of the helper methods will only return data
    # once `dataset` has been called.
    dataset.all.sort{|x,y| @ids.index(x[:archival_object_id]) <=> @ids.index(y[:archival_object_id])}.each do |row|
      row_ix += 1
      row_style = nil
      
      if has_digital_object_instances?(row[:archival_object_id])
        row_style = highlight
      end

      sheet.write_row(row_ix, 0, column_definitions.map {|col| col[:proc].call(row) }, row_style)
    end

    wb.close
    io.string
  end

  def has_digital_object_instances?(id)
    @has_digital_object_instances.include?(id)
  end

  def creation_dates_for_resource(id)
    @resource_creation_dates.fetch(id, [])
  end

  def creation_dates_for_archival_object(id)
    @creation_dates.fetch(id, [])
  end

  def all_dates_for_archival_object(id)
    @all_dates.fetch(id, [])
  end

  def extents_for_archival_object(id)
    @extents.fetch(id, [])
  end

  def notes_for_archival_object(id)
    @notes.fetch(id, {})
  end

  def notes_for_resource(id)
    @resource_notes.fetch(id, {})
  end

  def breadcrumb_for_archival_object(id)
    crumbs = @breadcrumbs.fetch(id)
    crumbs.collect{|ao|
      display_string = ao.fetch('title') || ao.fetch('display_string')

      # RULE:
      # Only include "Series X" if the component unique identifier has been
      # filled out in ASpace (otherwise, just include the title)
      if ao.fetch('level') == 'series' && !ao.fetch('component_id', nil).nil?
        display_string = "Series #{romanize(ao.fetch('component_id'))}. #{display_string}"
      end

      strip_html(display_string)
    }.join('. ')
  end

  def romanize(number)
    # based on code seen at:
    # https://stackoverflow.com/questions/26092510/roman-numerals-in-ruby
    n = number.to_i
    return number if n == 0

    @romans ||= { 1000 => "M", 900 => "CM", 500 => "D", 400 => "CD", 100 => "C",
                  90 => "XC", 50 => "L", 40 => "XL", 10 => "X",
                  9 => "IX", 5 => "V", 4 => "IV", 1 => "I" } 

    @romans.reduce("") do |res, (arab, roman)|
      whole_part, n = n.divmod(arab)
      res << roman * whole_part
    end
  end

  private

  def dataset
    ds = SubContainer
           .left_outer_join(:instance, :instance__id => :sub_container__instance_id)
           .left_outer_join(:archival_object, :archival_object__id => :instance__archival_object_id)
           .left_outer_join(:resource, :resource__id => :archival_object__root_record_id)
           .left_outer_join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
           .left_outer_join(:top_container, :top_container__id => :top_container_link_rlshp__top_container_id)
           .left_outer_join(:enumeration_value, { :level_enum__id => :archival_object__level_id }, :table_alias => :level_enum)
           .left_outer_join(:enumeration_value, { :type_enum__id => :sub_container__type_2_id }, :table_alias => :type_enum)
           .filter(:instance__archival_object_id => @ids)

    # archival object bits
    ds = ds.select_append(Sequel.as(:archival_object__id, :archival_object_id))
    ds = ds.select_append(Sequel.as(:archival_object__repo_id, :repo_id))
    ds = ds.select_append(Sequel.as(:archival_object__title, :archival_object_title))
    ds = ds.select_append(Sequel.as(:level_enum__value, :archival_object_level))

    # resource bits
    ds = ds.select_append(Sequel.as(:resource__id, :resource_id))
    ds = ds.select_append(Sequel.as(:resource__identifier, :resource_identifier))
    ds = ds.select_append(Sequel.as(:resource__title, :resource_title))
    ds = ds.select_append(Sequel.as(:resource__ead_location, :resource_ead_location))

    # top container bits 
    ds = ds.select_append(Sequel.as(:top_container__indicator, :top_container_indicator))
    ds = ds.select_append(Sequel.as(:top_container__barcode, :top_container_barcode))

    # sub_container bits
    ds = ds.select_append(Sequel.as(:sub_container__indicator_2, :sub_container_indicator))
    ds = ds.select_append(Sequel.as(:type_enum__value, :sub_container_type))

    prepare_resource_creation_dates
    prepare_ao_creation_dates
    prepare_extents
    prepare_notes
    prepare_breadcrumbs
    prepare_digital_object_instance_flags

    ds
  end

  def extract_ids
    @uris.map { |uri|
      parsed = JSONModel.parse_reference(uri)

      # only archival_objects
      next unless parsed[:type] == "archival_object"

      parsed[:id]
    }.compact
  end

  def prepare_resource_creation_dates
    @all_resource_dates = {}
    @resource_creation_dates = {}

    creation_enum_id = EnumerationValue
                         .filter(:enumeration_id => Enumeration.filter(:name => 'date_label').select(:id))
                         .filter(:value => 'creation')
                         .select(:id)
                         .first[:id]

    ASDate
      .filter(:date__resource_id => @resource_id)
      .select(:resource_id,
              :expression,
              :begin,
              :end,
              Sequel.as(:date__date_type_id, :date_type_id),
              Sequel.as(:date__label_id, :label_id))
      .each do |row|
      @all_resource_dates[row[:resource_id]] ||= []
      @all_resource_dates[row[:resource_id]] << row

      if row[:label_id] == creation_enum_id
        @resource_creation_dates[row[:resource_id]] ||= []
        @resource_creation_dates[row[:resource_id]] << row
      end
    end
  end

  def prepare_ao_creation_dates
    @all_dates = {}
    @creation_dates = {}

    creation_enum_id = EnumerationValue
                         .filter(:enumeration_id => Enumeration.filter(:name => 'date_label').select(:id))
                         .filter(:value => 'creation')
                         .select(:id)
                         .first[:id]

    ASDate
      .filter(:date__archival_object_id => @ids)
      .select(:archival_object_id,
              :expression,
              :begin,
              :end,
              Sequel.as(:date__date_type_id, :date_type_id),
              Sequel.as(:date__label_id, :label_id))
      .each do |row|
      @all_dates[row[:archival_object_id]] ||= []
      @all_dates[row[:archival_object_id]] << row

      if row[:label_id] == creation_enum_id
        @creation_dates[row[:archival_object_id]] ||= []
        @creation_dates[row[:archival_object_id]] << row
      end
    end
  end

  def prepare_extents
    @extents = {}

    Extent
     .left_outer_join(:enumeration_value, { :portion_enum__id => :extent__portion_id }, :table_alias => :portion_enum)
     .left_outer_join(:enumeration_value, { :extent_type_enum__id => :extent__extent_type_id }, :table_alias => :extent_type_enum)
     .filter(:extent__archival_object_id => @ids)
     .select(Sequel.as(:extent__archival_object_id, :archival_object_id),
             Sequel.as(:portion_enum__value, :portion),
             Sequel.as(:extent_type_enum__value, :extent_type),
             Sequel.as(:extent__number, :number))
     .each do |row|

      @extents[row[:archival_object_id]] ||= []
      @extents[row[:archival_object_id]] << row
    end
  end

  def prepare_notes
    @notes = {}
    @resource_notes = {}

    Note
      .filter(:publish => 1)
      .filter(:note__archival_object_id => @ids)
      .or(:note__resource_id => @resource_id)
      .select(Sequel.as(:note__archival_object_id, :archival_object_id),
              Sequel.as(:note__resource_id, :resource_id),
              Sequel.as(:note__notes, :note))
      .each do |row|
      parsed = parse_note(row)

      next if parsed.nil?

      # group notes by type
      if row[:archival_object_id]
        @notes[row[:archival_object_id]] ||= {}
        @notes[row[:archival_object_id]][parsed.fetch('type')] ||= []
        @notes[row[:archival_object_id]][parsed.fetch('type')] << parsed.fetch('note')
      elsif row[:resource_id]
        @resource_notes[row[:resource_id]] ||= {}
        @resource_notes[row[:resource_id]][parsed.fetch('type')] ||= []
        @resource_notes[row[:resource_id]][parsed.fetch('type')] << parsed.fetch('note')
      end
    end
  end

  def parse_note(row)
    note = ASUtils.json_parse(row[:note])

    {
      'type' => note.fetch('type', note.fetch('jsonmodel_type')),
      'note' => note.to_h,
    }
  end


  def prepare_breadcrumbs
    child_to_parent_map = {}
    node_to_position_map = {}
    node_to_root_record_map = {}
    node_to_data_map = {}

    @breadcrumbs = {}

    DB.open do |db|
      ## Fetch our mappings of nodes to parents and nodes to positions
      nodes_to_expand = @ids

      while !nodes_to_expand.empty?
        # Get the set of parents of the current level of nodes
        next_nodes_to_expand = []

        db[:archival_object]
          .left_outer_join(:enumeration_value, { :level_enum__id => :archival_object__level_id }, :table_alias => :level_enum)
          .filter(:archival_object__id => nodes_to_expand)
          .select(Sequel.as(:archival_object__id, :id),
                  Sequel.as(:archival_object__parent_id, :parent_id),
                  Sequel.as(:archival_object__root_record_id, :root_record_id),
                  Sequel.as(:archival_object__position, :position),
                  Sequel.as(:archival_object__title, :title),
                  Sequel.as(:archival_object__display_string, :display_string),
                  Sequel.as(:archival_object__component_id, :component_id),
                  Sequel.as(:level_enum__value, :level),
                  Sequel.as(:archival_object__other_level, :other_level))
          .each do |row|
          child_to_parent_map[row[:id]] = row[:parent_id]
          node_to_position_map[row[:id]] = row[:position]
          node_to_data_map[row[:id]] = row
          node_to_root_record_map[row[:id]] = row[:root_record_id]
          next_nodes_to_expand << row[:parent_id]
        end

        nodes_to_expand = next_nodes_to_expand.compact.uniq
      end

      @ids.each do |node_id|
        path = []

        current_node = node_id
        while child_to_parent_map[current_node]
          parent_node = child_to_parent_map[current_node]

          data = node_to_data_map.fetch(parent_node)

          path << {"uri" => JSONModel::JSONModel(:archival_object).uri_for(parent_node, :repo_id => @repo_id),
                   "display_string" => data.fetch(:display_string),
                   "title" => data.fetch(:title),
                   "component_id" => data.fetch(:component_id),
                   "level" => data[:other_level] || data[:level]}

          current_node = parent_node
        end

        @breadcrumbs[node_id] = path.reverse
      end
    end
  end

  def prepare_digital_object_instance_flags
    @has_digital_object_instances = []

    Instance
      .left_outer_join(:instance_do_link_rlshp, :instance_do_link_rlshp__instance_id => :instance__id)
      .filter(:instance__archival_object_id => @ids)
      .filter(Sequel.~(:instance_do_link_rlshp__digital_object_id => nil))
      .select(Sequel.as(:instance__archival_object_id, :archival_object_id))
      .distinct
      .each do |row|
      @has_digital_object_instances << row[:archival_object_id]
    end
  end

  def local_record_id(row)
    "/repositories/#{row[:repo_id]}/archival_objects/#{row[:archival_object_id]}"
  end

  def call_number(row)
    JSON.parse(row[:resource_identifier]).compact.join(' ')
  end

  def box(row)
    row[:top_container_indicator]
  end

  def barcode(row)
    row[:top_container_barcode]
  end

  def folder(row)
    row[:sub_container_indicator] if row[:sub_container_type] == 'folder'
  end

  def host_title(row)
    strip_html(row[:resource_title])
  end

  def host_note(row)
    breadcrumb_for_archival_object(row[:archival_object_id])
  end

  def note(row)
    notes_for_archival_object(row[:archival_object_id])
      .map{|type, notes|
        next if type == 'scopecontent'
        next if type == 'accessrestrict'
        next if type == 'prefercite'

        notes_to_text(notes)
      }
      .flatten
      .compact
      .join(NEW_LINE_SEPARATOR)
  end

  def notes_to_text(notes)
    notes
      .map{|note_json| note_to_text(note_json)}
      .compact
      .map{|note_text| strip_html(note_text)}
  end

  def note_to_text(note_json)
    if note_json['jsonmodel_type'] == 'note_singlepart'
      note_json.fetch('content', []).join(NEW_LINE_SEPARATOR)
    elsif note_json['jsonmodel_type'] == 'note_multipart'
      note_json.fetch('subnotes', []).map{|subnote|
        note_to_text(subnote)
      }.compact.join(NEW_LINE_SEPARATOR)
    elsif note_json['jsonmodel_type'] == 'note_text'
      note_json['content']
    else
      # unsupported note type
    end
  end

  def abstract(row)
    notes_for_archival_object(row[:archival_object_id])
      .map{|type, notes|
        next unless type == 'scopecontent'

        notes_to_text(notes)
      }
      .compact
      .flatten
      .join(NEW_LINE_SEPARATOR)
  end

  def title(row)
    strip_html(row[:archival_object_title])
  end

  def creator(row)
    creators_for_archival_object(row[:archival_object_id])
      .map{|row| (row[:person] || row[:corporate_entity] || row[:family] || row[:software])}
      .join(NEW_LINE_SEPARATOR)
  end

  def creation_date(row)
    creation_dates_for_archival_object(row[:archival_object_id])
      .map{|row| row[:expression] || [row[:begin], row[:end]].compact.join(' - ')}
      .join(NEW_LINE_SEPARATOR)
  end

  def physical_description(row)
    extents_for_archival_object(row[:archival_object_id]).map{|row|
      type = I18n.t("enumerations.extent_extent_type.#{row[:extent_type]}",
                    :default => row[:extent_type])
      "#{row[:number]} #{type}"
    }.join(NEW_LINE_SEPARATOR)
  end


  def ead_location(row)
    row[:resource_ead_location]
  end

  def citation_note(row)
    archival_object_citation = notes_for_archival_object(row[:archival_object_id])
                                .map{|type, notes|
                                  next unless type == 'prefercite'

                                  notes_to_text(notes)
                                }
                                .compact
                                .flatten

    return archival_object_citation.join(NEW_LINE_SEPARATOR) unless archival_object_citation.empty?

    notes_for_resource(row[:resource_id])
      .map{|type, notes|
        next unless type == 'prefercite'

        notes_to_text(notes)
      }
      .compact
      .flatten
      .join(NEW_LINE_SEPARATOR)
  end

  def start_year(row)
    all_years(row, :start)
  end

  def end_year(row)
    all_years(row, :end)
  end

  def all_years(row, mode = :range)
    dates = all_dates_for_archival_object(row[:archival_object_id])

    return if dates.empty?

    ranges = []

    dates.each do |date|
      from = nil
      to = nil

      if date[:begin] && date[:begin] =~ /^[0-9][0-9][0-9][0-9]/
        year = date[:begin][0..3].to_i
        from = [from, year].compact.min
        to = year if to.nil?
      end

      if date[:end] && date[:end] =~ /^[0-9][0-9][0-9][0-9]/
        year = date[:end][0..3].to_i
        from = [from, year].compact.min
        to = [to, year].compact.max
      end

      next if from.nil?

      ranges << [from, to]
    end

    return if ranges.empty?

    full_range = ranges
      .collect{|r| (r[0]..r[1]).to_a}
      .flatten
      .uniq
      .sort

    case mode
    when :start
      full_range.first
    when :end
      full_range.last
    else
      full_range.join(NEW_LINE_SEPARATOR)
    end
  end

  # What we'd like here is the dates from the Creation dates field formated as Inclusive/Single Date(s) (Bulk: Bulk Dates) if Bulk exists
  # ex. 1924-1967 (Bulk: 1930-1939) or 1851 Nov. 3 or 1851-1853
  # Clarification on cardinality:
  #   There are cases where there is more than one inclusive/single creation date object for an item (ex. Nov 3 1892 and April 8 1893).
  #   In cases like these, we would like each date object separated with a semi-color (so we would get "Nov 3 1892; April 8 1893").
  # HM: assuming only zero or none bulk creation dates (i.e. only looking at the first).
  # New requirement: 66 should be the collection date (if it exists)
  def collection_creation_years(row)
    dates = creation_dates_for_resource(@resource_id)

    return if dates.empty?

    non_bulk = dates.select{|d| d.date_type != 'bulk'}
    bulk = dates.find{|d| d.date_type == 'bulk'}

    def fmt_date(date) 
      date[:expression] || [(date[:begin] || '').sub(/-.*/, ''), (date[:end] || '').sub(/-.*/, '')].select{|d| !d.empty?}.compact.uniq.join('-')
    end

    out = non_bulk.map{|d| fmt_date(d)}.join('; ')
    out += " (Bulk: #{fmt_date(bulk)})" if bulk

    out
  end

  def strip_html(string)
    return if string.nil?

    string.gsub(/<\/?[^>]*>/, "")
  end

end
