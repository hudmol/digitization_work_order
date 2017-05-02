class LadybirdExport

  COLUMNS = [
    {:header => "{F1}",                :proc => Proc.new {|row| ''}},
    {:header => "{F2}",                :proc => Proc.new {|row| ''}},
    {:header => "{F3}",                :proc => Proc.new {|row| ''}},
    {:header => "{F4}",                :proc => Proc.new {|row| ''}},
    {:header => "{F5}",                :proc => Proc.new {|row| ''}},
    {:header => "{F6}",                :proc => Proc.new {|row| ''}},
    {:header => "{F20}",               :proc => Proc.new {|row| ''}},
    {:header => "{F21}",               :proc => Proc.new {|row| ''}},
    # Local record ID {fdid=56}
    {:header => "{fdid=56}",           :proc => Proc.new {|row| local_record_id(row)}},
    # Call number {fdid=58}
    {:header => "{fdid=58}",           :proc => Proc.new {|row| call_number(row)}},
    # Box {fdid=60}
    {:header => "{fdid=60}",           :proc => Proc.new {|row| box(row)}},
    # Folder {fdid=61}
    {:header => "{fdid=61}",           :proc => Proc.new {|row| folder(row)}},
    # Host, Creator {fdid=62}
    {:header => "{fdid=62}",           :proc => Proc.new {|row| resource_creator(row)}},
    # Host, Title {fdid=63}
    {:header => "{fdid=63}",           :proc => Proc.new {|row| resource_title(row)}},
    # Host, note {fdid=68}
    {:header => "{fdid=68}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=69}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=70}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=79}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=82}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=84}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=86}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=87}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=88}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=90}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=91}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=98}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=99}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=100}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=102}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=103}",           :proc => Proc.new {|row| ''}},
    # Barcode {fdid=105}
    {:header => "{fdid=105}",           :proc => Proc.new {|row| barcode(row)}},
    {:header => "{fdid=106}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=156}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=180}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=187}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=275}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=280}",           :proc => Proc.new {|row| ''}},
    {:header => "{fdid=288}",           :proc => Proc.new {|row| ''}},
  ]

  def initialize(uris)
    @uris = uris
    @ids = archival_object_ids
  end

  def to_stream
    rows = []

    dataset.each do |row|
      result = {}
      COLUMNS.map {|col|
        result[col.fetch(:header)] = col[:proc].call(row)
      }
      rows << result
    end

    rows.to_json
  end

  private

  def dataset
    ds = SubContainer
           .left_outer_join(:instance, :instance__id => :sub_container__instance_id)
           .left_outer_join(:archival_object, :archival_object__id => :instance__archival_object_id)
           .left_outer_join(:resource, :resource__id => :archival_object__root_record_id)
           .left_outer_join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
           .left_outer_join(:top_container, :top_container__id => :top_container_link_rlshp__top_container_id)
           .filter(:instance__archival_object_id => @ids)

    # ao uri
    ds = ds.select_append(Sequel.as(:archival_object__id, :archival_object_id))
    ds = ds.select_append(Sequel.as(:archival_object__repo_id, :repo_id))

    # resource bits
    ds = ds.select_append(Sequel.as(:resource__id, :resource_id))
    ds = ds.select_append(Sequel.as(:resource__identifier, :resource_identifier))
    ds = ds.select_append(Sequel.as(:resource__title, :resource_title))

    # top container bits 
    ds = ds.select_append(Sequel.as(:top_container__indicator, :top_container_indicator))
    ds = ds.select_append(Sequel.as(:top_container__barcode, :top_container_barcode))

    # sub_container bits
    ds = ds.select_append(Sequel.as(:sub_container__indicator_2, :sub_container_folder))

    # dates via archival object

    # extent via archival object

    # notes via archival object

    # subject[name] via archival object
    # subject[term] via archival object
    # subject[geographic] via archival object

    # top_container barcode

    # linked_agents_rlshp via resource where role_id for enum 'linked_agent_role' and enum value 'creator'
    # linked_agents_rlshp via archival object where role_id for enum 'linked_agent_role' and enum value 'creator'
    

    ds
  end

  def archival_object_ids
    ids = []

    @uris.each do |uri|
      parsed = JSONModel.parse_reference(uri)

      # only archival_objects
      next unless parsed[:type] == "archival_object"

      ids << parsed[:id]
    end

    ids
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

  def self.resource_creator(row)
    ''
  end

  def self.resource_title(row)
    row[:resource_title]
  end

end