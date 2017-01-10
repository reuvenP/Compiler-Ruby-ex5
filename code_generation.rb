require './compilation_engine'
require 'rexml/document'

class CodeGeneration
  def initialize(path)
    engine = CompilationEngine.new(path)
    @parse_tree_array = engine.get_parse_tree_array
    @parse_tree_array.each {|tree|
      doc = REXML::Document.new(tree.to_s)
      root = doc.root
      root.elements.each {|e|
        if e.name == 'subroutineDec'
          e.elements.each{|ee|
            puts ee
          }
        end
      }
    }
  end
end

cg = CodeGeneration.new(ARGV[0])