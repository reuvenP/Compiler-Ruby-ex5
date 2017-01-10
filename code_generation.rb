require './compilation_engine'
require 'rexml/document'

class CodeGeneration
  def initialize(path)
    engine = CompilationEngine.new(path)
    @parse_tree_array = engine.get_parse_tree_array
    @parse_tree_array.each {|tree|
      doc = REXML::Document.new(tree.to_s)
      root = doc.root
      puts root.elements["/"].name
    }
  end
end

cg = CodeGeneration.new(ARGV[0])