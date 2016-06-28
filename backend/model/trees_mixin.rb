module Trees
  def quick_tree
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []

    query = build_node_query

    has_children = {}

    offset = 0
    while true
      now = Time.now
      nodes = query.limit(NODE_PAGE_SIZE, offset).all

      nodes.each do |node|
        if node.parent_id
          links[node.parent_id] ||= []
          links[node.parent_id] << [node.position, node.id]
        else
          top_nodes << [node.position, node.id]
        end

        properties[node.id] = {
          :title => node[:title],
          :id => node.id,
          :record_uri => self.class.uri_for(node_type, node.id),
          :publish => node.respond_to?(:publish) ? node.publish===1 : true,
          :suppressed => node.respond_to?(:suppressed) ? node.suppressed===1 : false,
          :node_type => node_type.to_s
        }
      end

      if nodes.empty?
        break
      else
        offset += NODE_PAGE_SIZE
      end
    end

    result = {
      :title => self.title,
      :id => self.id,
      :node_type => root_type.to_s,
      :publish => self.respond_to?(:publish) ? self.publish===1 : true,
      :suppressed => self.respond_to?(:suppressed) ? self.suppressed===1 : false,
      :children => top_nodes.sort_by(&:first).map {|position, node| self.class.assemble_tree(node, links, properties)},
      :record_uri => self.class.uri_for(root_type, self.id)
    }

    JSONModel("#{self.class.root_type}_tree".intern).from_hash(result, true, true)
  end
end