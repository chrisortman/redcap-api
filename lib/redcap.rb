require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect "api" => "API"
loader.inflector.inflect "redcap" => "RedCAP"
loader.setup

module RedCAP
  class Error < StandardError; end
  # Your code goes here...
end
