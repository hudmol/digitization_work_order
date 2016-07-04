require 'cgi'

class WorkOrderController < ApplicationController

  set_access_control "view_repository" => [:index, :generate_report]

  def index
    @uri = params[:resource]
    @tree = escape_xml_characters(load_tree)
  end

  def generate_report
    p "Work order selected URIs: "
    p params[:selected]

    raise "Not implemented"
  end

  private

  def escape_xml_characters(tree)
    result = tree.merge('title' => CGI.escapeHTML(tree['title']))

    if tree['children']
      result.merge('children' => tree['children'].map {|child| escape_xml_characters(child)})
    else
      result
    end
  end

  def load_tree
    JSONModel::HTTP::get_json(@uri + "/small_tree")
  end

end
