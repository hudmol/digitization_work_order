class SmallTree

  def self.for_resource(resource_id)
    tree = Resource.get_or_die(resource_id).tree
    build_from(tree)
  end

  private

  def self.build_from(tree)
    {
      :uri => tree['record_uri'],
      :title => tree['title'],
      :children => tree['children'].map { |child| self.build_from(child) }
    }
  end

end
