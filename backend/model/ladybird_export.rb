require 'axlsx'

class LadybirdExport

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
      {:header => "{F1}",                :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F2}",                :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F3}",                :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F4}",                :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F5}",                :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F6}",                :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F20}",               :proc => Proc.new {|row| nil }}, #BLANK!
      {:header => "{F21}",               :proc => Proc.new {|row| nil }}, #BLANK!
      # Local record ID {fdid=56}
      {:header => "{fdid=56}",           :proc => Proc.new {|row| local_record_id(row)}},
      # Call number {fdid=58}
      {:header => "{fdid=58}",           :proc => Proc.new {|row| call_number(row)}},
      # Box {fdid=60}
      {:header => "{fdid=60}",           :proc => Proc.new {|row| box(row)}},
      # Folder {fdid=61}
      {:header => "{fdid=61}",           :proc => Proc.new {|row| folder(row)}},
      # Host, Creator {fdid=62}
      {:header => "{fdid=62}",           :proc => Proc.new {|row| host_creator(row)}},
      # Host, Title {fdid=63}
      {:header => "{fdid=63}",           :proc => Proc.new {|row| host_title(row)}},
      # Host, note {fdid=68}
      {:header => "{fdid=68}",           :proc => Proc.new {|row| host_note(row)}},
      # Creator {fdid=69}
      {:header => "{fdid=69}",           :proc => Proc.new {|row| creator(row)}},
      # Title {fdid=70}
      {:header => "{fdid=70}",           :proc => Proc.new {|row| title(row)}},
      # Date, created {fdid=79}
      {:header => "{fdid=79}",           :proc => Proc.new {|row| creation_date(row)}},
      # Physical description {fdid=82}
      {:header => "{fdid=82}",           :proc => Proc.new {|row| physical_description(row)}},
      # Language {fdid=84}
      {:header => "{fdid=84}",           :proc => Proc.new {|row| language(row)}},
      # Note {fdid=86}
      {:header => "{fdid=86}",           :proc => Proc.new {|row| note(row)}},
      # Abstract {fdid=87}
      {:header => "{fdid=87}",           :proc => Proc.new {|row| abstract(row)}},
      # Subject, name {fdid=88}
      {:header => "{fdid=88}",           :proc => Proc.new {|row| name_subjects(row)}},
      # Subject, topic {fdid=90}
      {:header => "{fdid=90}",           :proc => Proc.new {|row| topic_subjects(row)}},
      # Subject, geographic {fdid=91}
      {:header => "{fdid=91}",           :proc => Proc.new {|row| geo_subjects(row)}},
      # Genre {fdid=98}
      {:header => "{fdid=98}",           :proc => Proc.new {|row| nil }}, #BLANK!
      # Type of resource {fdid=99}
      {:header => "{fdid=99}",           :proc => Proc.new {|row| nil }}, #BLANK!
      # Location, YUL {fdid=100}
      {:header => "{fdid=100}",           :proc => Proc.new {|row| 'Beinecke Rare Book and Manuscript Library, Yale University {id=159091}'}},
      # Access condition {fdid=102}
      {:header => "{fdid=102}",           :proc => Proc.new {|row| nil}}, #BLANK!
      # Restriction {fdid=103}
      {:header => "{fdid=103}",           :proc => Proc.new {|row| nil }}, #BLANK!
      # Barcode {fdid=105}
      {:header => "{fdid=105}",           :proc => Proc.new {|row| barcode(row)}},
      # YFAD {fdid=106}
      {:header => "{fdid=106}",           :proc => Proc.new {|row| ead_location(row)}},
      # Citation {fdid=156}
      {:header => "{fdid=156}",           :proc => Proc.new {|row| citation_note(row)}},
      # Item Permission  {fdid=180}
      {:header => "{fdid=180}",           :proc => Proc.new {|row| nil }}, #BLANK!
      # Studio Notes {fdid=187}
      {:header => "{fdid=187}",           :proc => Proc.new {|row| nil }}, #BLANK!
      # Digital Collection {fdid=275}
      {:header => "{fdid=275}",           :proc => Proc.new {|row| nil}}, #BLANK!
      # ISO Date {fdid=280)
      {:header => "{fdid=280}",           :proc => Proc.new {|row| all_years(row)}},
      # Content type {fdid=288}
      {:header => "{fdid=288}",           :proc => Proc.new {|row| nil}}, #BLANK!
    ]
  end

  def to_stream
    p = Axlsx::Package.new
    wb = p.workbook

    wb.add_worksheet(:name => 'Digitization Work Order') do |sheet|
      highlight = sheet.styles.add_style :bg_color => "E8F4FF"

      sheet.add_row column_definitions.collect{|col| col.fetch(:header)}

      # PLEASE NOTE
      # `dataset` hits the database to return all the instance rows but it also
      # fire a series of extra queries from which we aggregate all multi-valued
      # fields required for the report. These values are stored as instance
      # variables and as such many of the helper methods will only return data
      # once `dataset` has been called.
      dataset.each do |row|
        row_style = nil

        if has_digital_object_instances?(row[:archival_object_id])
          row_style = highlight
        end

        sheet.add_row column_definitions.map {|col| col[:proc].call(row) }, :style => row_style
      end
    end

    p.to_stream
  end

  def has_digital_object_instances?(id)
    @has_digital_object_instances.include?(id)
  end

  def creators_for_archival_object(id)
    @creators.fetch(id, [])
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

  def creators_for_resource(id)
    @resource_creators.fetch(id, [])
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
        # only prepend title with "Series" (if not already there)
        unless display_string.start_with?('Series')
          display_string = "Series #{display_string}"
        end
      end

      display_string
    }.join('. ')
  end

  def name_subjects_for_archival_object(id)
    @agent_subjects.fetch(id, [])
  end

  def topic_subjects_for_archival_object(id)
    @subjects.fetch(id, []).select{|s| s[:first_term_type] == 'topical'}
  end

  def geo_subjects_for_archival_object(id)
    @subjects.fetch(id, []).select{|s| s[:first_term_type] == 'geographic'}
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
           .left_outer_join(:enumeration_value, { :level_enum__id => :archival_object__level_id }, :table_alias => :level_enum)
           .filter(:instance__archival_object_id => @ids)

    # archival object bits
    ds = ds.select_append(Sequel.as(:archival_object__id, :archival_object_id))
    ds = ds.select_append(Sequel.as(:archival_object__repo_id, :repo_id))
    ds = ds.select_append(Sequel.as(:archival_object__title, :archival_object_title))
    ds = ds.select_append(Sequel.as(:level_enum__value, :archival_object_level))
    ds = ds.select_append(Sequel.as(:language_enum__value, :archival_object_language))

    # resource bits
    ds = ds.select_append(Sequel.as(:resource__id, :resource_id))
    ds = ds.select_append(Sequel.as(:resource__identifier, :resource_identifier))
    ds = ds.select_append(Sequel.as(:resource__title, :resource_title))
    ds = ds.select_append(Sequel.as(:resource__ead_location, :resource_ead_location))

    # top container bits 
    ds = ds.select_append(Sequel.as(:top_container__indicator, :top_container_indicator))
    ds = ds.select_append(Sequel.as(:top_container__barcode, :top_container_barcode))

    # sub_container bits
    ds = ds.select_append(Sequel.as(:sub_container__indicator_2, :sub_container_folder))

    prepare_creation_dates
    prepare_related_agents
    prepare_extents
    prepare_notes
    prepare_breadcrumbs
    prepare_subjects
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

  def prepare_creation_dates
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

  def prepare_related_agents
    @creators = {}
    @resource_creators = {}
    @agent_subjects = {}

    subject_enum_id = nil
    creator_enum_id = nil

    EnumerationValue
      .filter(:enumeration_id => Enumeration.filter(:name => 'linked_agent_role').select(:id))
      .filter(:value => ['creator', 'subject'])
      .select(:id, :value)
      .each do |row|
      if row[:value] == 'creator'
        creator_enum_id = row[:id]
      elsif row[:value] == 'subject'
        subject_enum_id = row[:id]
      end
    end

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
      .and(Sequel.|({:linked_agents_rlshp__role_id => creator_enum_id, :linked_agents_rlshp__role_id => subject_enum_id}))
      .select(Sequel.as(:archival_object__id, :archival_object_id),
              Sequel.as(:linked_agents_rlshp__role_id, :role_id),
              Sequel.as(:name_person__sort_name, :person),
              Sequel.as(:name_corporate_entity__sort_name, :corporate_entity),
              Sequel.as(:name_family__sort_name, :family),
              Sequel.as(:name_software__sort_name, :software))
      .distinct
      .each do |row|

      if row[:role_id] == creator_enum_id
        @creators[row[:archival_object_id]] ||= []
        @creators[row[:archival_object_id]] << row
      elsif row[:role_id] == subject_enum_id
        @agent_subjects[row[:archival_object_id]] ||= []
        @agent_subjects[row[:archival_object_id]] << row
      end
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
    @resource_notes = {}

    Note
      .filter(:note__archival_object_id => @ids)
      .or(:note__resource_id => @resource_id)
      .select(Sequel.as(:note__archival_object_id, :archival_object_id),
              Sequel.as(:note__resource_id, :resource_id),
              Sequel.as(:note__notes, :note))
      .each do |row|

      if row[:archival_object_id]
        @notes[row[:archival_object_id]] ||= {}

        parsed = parse_note(row)

        next if parsed.nil?

        @notes[row[:archival_object_id]][parsed.fetch('type')] ||= []
        @notes[row[:archival_object_id]][parsed.fetch('type')] << parsed.fetch('notes')
      elsif row[:resource_id]
        @resource_notes[row[:resource_id]] ||= {}

        parsed = parse_note(row)

        next if parsed.nil?

        @resource_notes[row[:resource_id]][parsed.fetch('type')] ||= []
        @resource_notes[row[:resource_id]][parsed.fetch('type')] << parsed.fetch('notes')
      end
    end
  end

  def parse_note(row)
    note = ASUtils.json_parse(row[:note])

    type = note.fetch('type')
    subnotes = note.fetch('subnotes', nil)

    return unless subnotes

    {
      'type' => type,
      'notes' => subnotes.collect{|n| n.fetch('content', nil)}.compact
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


  def prepare_subjects
    @subjects = {}

    current = nil

    Subject
      .left_outer_join(:subject_rlshp, :subject_rlshp__subject_id => :subject__id)
      .left_outer_join(:subject_term, :subject_term__subject_id => :subject__id)
      .left_outer_join(:term, :term__id => :subject_term__term_id)
      .left_outer_join(:enumeration_value, { :term_type_enum__id => :term__term_type_id }, :table_alias => :term_type_enum)
      .filter(:subject_rlshp__archival_object_id => @ids)
      .select(Sequel.as(:subject_rlshp__archival_object_id, :archival_object_id),
              Sequel.as(:subject__id, :subject_id),
              Sequel.as(:term_type_enum__value, :term_type),
              Sequel.as(:subject__title, :display_string))
      .order(:subject__id, :subject_term__id)
      .each do |row|
      @subjects[row[:archival_object_id]] ||= []
      if current.nil? || current[:subject_id] != row[:subject_id]
        current = {
          :subject_id => row[:subject_id],
          :display_string => row[:display_string],
          :first_term_type => row[:term_type]
        }

        @subjects[row[:archival_object_id]] << current
      else
        # we only care about the first term type
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
    row[:sub_container_folder]
  end

  def host_creator(row)
    creators_for_resource(row[:archival_object_id])
      .map{|row| (row[:person] || row[:corporate_entity] || row[:family] || row[:software])}
      .join(NEW_LINE_SEPARATOR)
  end

  def host_title(row)
    row[:resource_title]
  end

  def host_note(row)
    breadcrumb_for_archival_object(row[:archival_object_id])
  end

  def note(row)
    notes_for_archival_object(row[:archival_object_id])
      .map{|type, content|
        next if type == 'scopecontent'
        next if type == 'accessrestrict'
        next if type == 'prefercite'
  
        content.flatten
      }
      .flatten
      .compact
      .join(NEW_LINE_SEPARATOR)
  end

  def abstract(row)
    notes_for_archival_object(row[:archival_object_id])
      .map{|type, content|
        next unless type == 'scopecontent'
        content.flatten
      }
      .compact
      .flatten
      .join(NEW_LINE_SEPARATOR)
  end

  def title(row)
    row[:archival_object_title]
  end

  def creator(row)
    creators_for_archival_object(row[:archival_object_id])
      .map{|row| (row[:person] || row[:corporate_entity] || row[:family] || row[:software])}
      .join(NEW_LINE_SEPARATOR)
  end

  def language(row)
    row[:archival_object_language]
  end

  def creation_date(row)
    creation_dates_for_archival_object(row[:archival_object_id])
      .map{|row| row[:expression] || [row[:begin], row[:end]].compact.join(' - ')}
      .join(NEW_LINE_SEPARATOR)
  end

  def physical_description(row)
    extents_for_archival_object(row[:archival_object_id])
      .map{|row| "#{row[:number]} #{row[:extent_type]} (#{row[:portion]})" }
      .join(NEW_LINE_SEPARATOR)
  end

  def name_subjects(row)
    name_subjects_for_archival_object(row[:archival_object_id])
      .map{|row| (row[:person] || row[:corporate_entity] || row[:family] || row[:software])}
      .join(NEW_LINE_SEPARATOR)
  end

  def topic_subjects(row)
    topic_subjects_for_archival_object(row[:archival_object_id])
      .map{|row| row[:display_string]}
      .join(NEW_LINE_SEPARATOR)
  end

  def geo_subjects(row)
    geo_subjects_for_archival_object(row[:archival_object_id])
      .map{|row| row[:display_string]}
      .join(NEW_LINE_SEPARATOR)
  end

  def ead_location(row)
    row[:resource_ead_location]
  end

  def citation_note(row)
    archival_object_citation = notes_for_archival_object(row[:archival_object_id])
                                .map{|type, content|
                                  next unless type == 'prefercite'
                                  content.flatten
                                }
                                .compact
                                .flatten

    return archival_object_citation.join(NEW_LINE_SEPARATOR) unless archival_object_citation.empty?

    notes_for_resource(row[:resource_id])
      .map{|type, content|
        next unless type == 'prefercite'
        content.flatten
      }
      .compact
      .flatten
      .join(NEW_LINE_SEPARATOR)
  end

  def all_years(row)
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

    ranges
      .collect{|r| (r[0]..r[1]).to_a}
      .flatten
      .uniq
      .sort
      .join(NEW_LINE_SEPARATOR)
  end

end