class LadybirdExport

  def initialize(uris)
    @uris = uris
  end

  def to_stream
    @uris.inspect
  end

end