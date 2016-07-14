class DefaultGenerator < GeneratorInterface

  def generate(record)
    Sequence.get("/repositories/#{record.repo_id}/archival_objects/component_id_for_work_order")
  end

end
