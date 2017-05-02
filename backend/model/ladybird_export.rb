require 'axlsx'

class LadybirdExport

  COLUMNS = [
    {:header => "{F1}",                :proc => Proc.new {|row| nil }},
    {:header => "{F2}",                :proc => Proc.new {|row| nil }},
    {:header => "{F3}",                :proc => Proc.new {|row| nil }},
    {:header => "{F4}",                :proc => Proc.new {|row| nil }},
    {:header => "{F5}",                :proc => Proc.new {|row| nil }},
    {:header => "{F6}",                :proc => Proc.new {|row| nil }},
    {:header => "{F20}",               :proc => Proc.new {|row| nil }},
    {:header => "{F21}",               :proc => Proc.new {|row| nil }},
    # Local record ID {fdid=56}
    {:header => "{fdid=56}",           :proc => Proc.new {|row| local_record_id(row)}},
    # Call number {fdid=58}
    {:header => "{fdid=58}",           :proc => Proc.new {|row| call_number(row)}},
    # Box {fdid=60}
    {:header => "{fdid=60}",           :proc => Proc.new {|row| box(row)}},
    # Folder {fdid=61}
    {:header => "{fdid=61}",           :proc => Proc.new {|row| folder(row)}},
    # Host, Creator {fdid=62}
    {:header => "{fdid=62}",           :proc => Proc.new {|row, export| host_creator(row, export)}},
    # Host, Title {fdid=63}
    {:header => "{fdid=63}",           :proc => Proc.new {|row| host_title(row)}},
    # Host, note {fdid=68}
    {:header => "{fdid=68}",           :proc => Proc.new {|row, export| host_note(row, export)}},
    # Creator {fdid=69}
    {:header => "{fdid=69}",           :proc => Proc.new {|row, export| creator(row, export)}},
    # Title {fdid=70}
    {:header => "{fdid=70}",           :proc => Proc.new {|row, export| title(row, export)}},
    # Date, created {fdid=79}
    {:header => "{fdid=79}",           :proc => Proc.new {|row, export| creation_date(row, export)}},
    # Physical description {fdid=82}
    {:header => "{fdid=82}",           :proc => Proc.new {|row, export| physical_description(row, export)}},
    # Language {fdid=84}
    {:header => "{fdid=84}",           :proc => Proc.new {|row| language(row)}},
    # Note {fdid=86}
    {:header => "{fdid=86}",           :proc => Proc.new {|row, export| note(row, export)}},
    # Abstract {fdid=87}
    {:header => "{fdid=87}",           :proc => Proc.new {|row, export| abstract(row, export)}},
    # Subject, name {fdid=88}
    {:header => "{fdid=88}",           :proc => Proc.new {|row| 'FIXME'}},
    # Subject, topic {fdid=90}
    {:header => "{fdid=90}",           :proc => Proc.new {|row| 'FIXME'}},
    # Subject, geographic {fdid=91}
    {:header => "{fdid=91}",           :proc => Proc.new {|row| 'FIXME'}},
    # Genre {fdid=98}
    {:header => "{fdid=98}",           :proc => Proc.new {|row| nil }}, #BLANK!
    # Type of resource {fdid=99}
    {:header => "{fdid=99}",           :proc => Proc.new {|row| nil }}, #BLANK!
    # Location, YUL {fdid=100}
    {:header => "{fdid=100}",           :proc => Proc.new {|row| 'Beinecke Rare Book and Manuscript Library, Yale University {id=159091}'}},
    # Access condition {fdid=102}
    {:header => "{fdid=102}",           :proc => Proc.new {|row| 'FIXME'}},
    # Restriction {fdid=103}
    {:header => "{fdid=103}",           :proc => Proc.new {|row| nil }}, #BLANK!
    # Barcode {fdid=105}
    {:header => "{fdid=105}",           :proc => Proc.new {|row| barcode(row)}},
    # YFAD {fdid=106}
    {:header => "{fdid=106}",           :proc => Proc.new {|row| 'FIXME'}},
    # Citation {fdid=156}
    {:header => "{fdid=156}",           :proc => Proc.new {|row| 'FIXME'}},
    # Item Permission  {fdid=180}
    {:header => "{fdid=180}",           :proc => Proc.new {|row| nil }}, #BLANK!
    # Studio Notes {fdid=187}
    {:header => "{fdid=187}",           :proc => Proc.new {|row| nil }}, #BLANK!
    # Digital Collection {fdid=275}
    {:header => "{fdid=275}",           :proc => Proc.new {|row| 'FIXME'}},
    # ISO Date {fdid=280)
    {:header => "{fdid=280}",           :proc => Proc.new {|row| 'FIXME'}},
    # Content type {fdid=288}
    {:header => "{fdid=288}",           :proc => Proc.new {|row| 'FIXME'}},
  ]

  def initialize(uris)
    @uris = uris
    @ids = extract_ids
  end

  def to_stream
    p = Axlsx::Package.new
    wb = p.workbook

    wb.add_worksheet(:name => 'Digitization Work Order') do |sheet|
      sheet.add_row COLUMNS.collect{|col| col.fetch(:header)}
      dataset.each do |row|
        sheet.add_row COLUMNS.map {|col| col[:proc].call(row, self) }
      end
    end

    p.to_stream
  end

  def creators_for_archival_object(id)
    @creators.fetch(id, [])
  end

  def creation_dates_for_archival_object(id)
    @creation_dates.fetch(id, [])
  end

  def extents_for_archival_object(id)
    @extents.fetch(id, [])
  end

  def creators_for_resource(id)
    @resource_creators.fetch(id, [])
  end

  def notes_for_archival_object(id)
    @notes.fetch(id, {})
  end

  private

  def dataset
    ds = SubContainer
           .left_outer_join(:instance, :instance__id => :sub_container__instance_id)
           .left_outer_join(:archival_object, :archival_object__id => :instance__archival_object_id)
           .left_outer_join(:resource, :resource__id => :archival_object__root_record_id)
           .left_outer_join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
           .left_outer_join(:top_container, :top_container__id => :top_container_link_rlshp__top_container_id)
           .left_outer_join(:enumeration_value, { :language_enum__id => :archival_object__language_id }, :table_alias => :language_enum)
           .filter(:instance__archival_object_id => @ids)

    # archival object bits
    ds = ds.select_append(Sequel.as(:archival_object__id, :archival_object_id))
    ds = ds.select_append(Sequel.as(:archival_object__repo_id, :repo_id))
    ds = ds.select_append(Sequel.as(:archival_object__title, :archival_object_title))
    ds = ds.select_append(Sequel.as(:language_enum__value, :archival_object_language))

    # resource bits
    ds = ds.select_append(Sequel.as(:resource__id, :resource_id))
    ds = ds.select_append(Sequel.as(:resource__identifier, :resource_identifier))
    ds = ds.select_append(Sequel.as(:resource__title, :resource_title))

    # top container bits 
    ds = ds.select_append(Sequel.as(:top_container__indicator, :top_container_indicator))
    ds = ds.select_append(Sequel.as(:top_container__barcode, :top_container_barcode))

    # sub_container bits
    ds = ds.select_append(Sequel.as(:sub_container__indicator_2, :sub_container_folder))

    prepare_creation_dates
    prepare_creators
    prepare_extents
    prepare_notes

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

  def prepare_creation_dates
    @creation_dates = {}

    creation_enum_id = EnumerationValue
                         .filter(:enumeration_id => Enumeration.filter(:name => 'date_label').select(:id))
                         .filter(:value => 'creation')
                         .select(:id)

    ASDate
      .filter(:date__archival_object_id => @ids)
      .filter(:date__label_id => creation_enum_id)
      .select(:archival_object_id, :expression, :begin, :end)
      .each do |row|

      @creation_dates[row[:archival_object_id]] ||= []
      @creation_dates[row[:archival_object_id]] << row
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

  def prepare_creators
    @creators = {}
    @resource_creators = {}

    creator_enum_id = EnumerationValue
                        .filter(:enumeration_id => Enumeration.filter(:name => 'linked_agent_role').select(:id))
                        .filter(:value => 'creator')
                        .select(:id)

    ArchivalObject
      .left_outer_join(:linked_agents_rlshp, :linked_agents_rlshp__archival_object_id => :archival_object__id)
      .left_outer_join(:agent_person, :agent_person__id => :linked_agents_rlshp__agent_person_id)
      .left_outer_join(:agent_corporate_entity, :agent_corporate_entity__id => :linked_agents_rlshp__agent_corporate_entity_id)
      .left_outer_join(:agent_family, :agent_family__id => :linked_agents_rlshp__agent_family_id)
      .left_outer_join(:agent_software, :agent_software__id => :linked_agents_rlshp__agent_software_id)
      .left_outer_join(:name_person, :name_person__id => :agent_person__id)
      .left_outer_join(:name_corporate_entity, :name_corporate_entity__id => :agent_corporate_entity__id)
      .left_outer_join(:name_family, :name_family__id => :agent_family__id)
      .left_outer_join(:name_software, :name_software__id => :agent_software__id)
      .filter(:archival_object__id => @ids)
      .and(Sequel.|({:name_person__is_display_name => 1}, {:name_person__is_display_name => nil}))
      .and(Sequel.|({:name_corporate_entity__is_display_name => 1}, {:name_corporate_entity__is_display_name => nil}))
      .and(Sequel.|({:name_family__is_display_name => 1}, {:name_family__is_display_name => nil}))
      .and(Sequel.|({:name_software__is_display_name => 1}, {:name_software__is_display_name => nil}))
      .and(:linked_agents_rlshp__role_id => creator_enum_id)
      .select(Sequel.as(:archival_object__id, :archival_object_id),
              Sequel.as(:name_person__sort_name, :person),
              Sequel.as(:name_corporate_entity__sort_name, :corporate_entity),
              Sequel.as(:name_family__sort_name, :family),
              Sequel.as(:name_software__sort_name, :software))
      .distinct
      .each do |row|

      @creators[row[:archival_object_id]] ||= []
      @creators[row[:archival_object_id]] << row
    end

    Resource
      .left_outer_join(:linked_agents_rlshp, :linked_agents_rlshp__resource_id => :resource__id)
      .left_outer_join(:agent_person, :agent_person__id => :linked_agents_rlshp__agent_person_id)
      .left_outer_join(:agent_corporate_entity, :agent_corporate_entity__id => :linked_agents_rlshp__agent_corporate_entity_id)
      .left_outer_join(:agent_family, :agent_family__id => :linked_agents_rlshp__agent_family_id)
      .left_outer_join(:agent_software, :agent_software__id => :linked_agents_rlshp__agent_software_id)
      .left_outer_join(:name_person, :name_person__id => :agent_person__id)
      .left_outer_join(:name_corporate_entity, :name_corporate_entity__id => :agent_corporate_entity__id)
      .left_outer_join(:name_family, :name_family__id => :agent_family__id)
      .left_outer_join(:name_software, :name_software__id => :agent_software__id)
      .left_outer_join(:archival_object, :archival_object__root_record_id => :resource__id)
      .filter(:archival_object__id => @ids)
      .and(Sequel.|({:name_person__is_display_name => 1}, {:name_person__is_display_name => nil}))
      .and(Sequel.|({:name_corporate_entity__is_display_name => 1}, {:name_corporate_entity__is_display_name => nil}))
      .and(Sequel.|({:name_family__is_display_name => 1}, {:name_family__is_display_name => nil}))
      .and(Sequel.|({:name_software__is_display_name => 1}, {:name_software__is_display_name => nil}))
      .and(:linked_agents_rlshp__role_id => creator_enum_id)
      .select(Sequel.as(:resource__id, :resource_id),
              Sequel.as(:name_person__sort_name, :person),
              Sequel.as(:name_corporate_entity__sort_name, :corporate_entity),
              Sequel.as(:name_family__sort_name, :family),
              Sequel.as(:name_software__sort_name, :software))
      .distinct
      .each do |row|

      @resource_creators[row[:archival_object_id]] ||= []
      @resource_creators[row[:archival_object_id]] << row
    end
  end

  def prepare_notes
    @notes = {}

    Note
      .filter(:note__archival_object_id => @ids)
      .select(Sequel.as(:note__archival_object_id, :archival_object_id),
              Sequel.as(:note__notes, :note))
      .each do |row|

      @notes[row[:archival_object_id]] ||= {}

      note = ASUtils.json_parse(row[:note])

      type = note.fetch('type')
      subnotes = note.fetch('subnotes', nil)

      next unless subnotes

      content = subnotes.collect{|n| n.fetch('content', nil)}.compact

      @notes[row[:archival_object_id]][type] ||= []
      @notes[row[:archival_object_id]][type] << content
    end
  end

  def self.local_record_id(row)
    "/repositories/#{row[:repo_id]}/archival_objects/#{row[:archival_object_id]}"
  end

  def self.call_number(row)
    JSON.parse(row[:resource_identifier]).compact.join('.')
  end

  def self.box(row)
    row[:top_container_indicator]
  end

  def self.barcode(row)
    row[:top_container_barcode]
  end

  def self.folder(row)
    row[:sub_container_folder]
  end

  def self.host_creator(row, export)
    export
      .creators_for_resource(row[:archival_object_id])
      .map{|row| (row[:person] || row[:corporate_entity] || row[:family] || row[:software])}
      .join(' | ')
  end

  def self.host_title(row)
    row[:resource_title]
  end

  def self.host_note(row, export)
    # FIXME this is a breadcrumb
    'FIXME'
  end

  def self.note(row, export)
    export
      .notes_for_archival_object(row[:archival_object_id])
      .map{|type, content|
        next if type == 'scopecontent'
        next if type == 'accessrestrict'
  
        content.flatten
      }
      .flatten
      .compact
      .join(' | ')
  end

  def self.abstract(row, export)
    export
      .notes_for_archival_object(row[:archival_object_id])
      .map{|type, content|
        next unless type == 'scopecontent'
        content.flatten
      }
      .compact
      .flatten
      .join(' | ')
  end

  def self.title(row, export)
    # FIXME need to append dates or show date if no title 
    row[:archival_object_title]
  end

  def self.creator(row, export)
    export
      .creators_for_archival_object(row[:archival_object_id])
      .map{|row| (row[:person] || row[:corporate_entity] || row[:family] || row[:software])}
      .join(' | ')
  end

  def self.language(row)
    row[:archival_object_language]
  end

  def self.creation_date(row, export)
    export
      .creation_dates_for_archival_object(row[:archival_object_id])
      .map{|row| row[:expression] || [row[:begin], row[:end]].compact.join(' - ')}
      .join(' | ')
  end

  def self.physical_description(row, export)
    export
      .extents_for_archival_object(row[:archival_object_id])
      .map{|row| "#{row[:number]} #{row[:extent_type]} (#{row[:portion]})" }
      .join(' | ')
  end

end