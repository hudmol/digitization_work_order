require 'securerandom'

class DefaultGenerator < GeneratorInterface

  def generate(record)
    SecureRandom.hex
  end

end
