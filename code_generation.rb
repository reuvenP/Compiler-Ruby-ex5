require './compilation_engine'
require './vm_writer'
require './symbol_table'
require 'rexml/document'

class CodeGeneration
  def initialize(path)
    engine = CompilationEngine.new(path)
    @parse_tree_array = engine.get_parse_tree_array
    @parse_tree_array.each {|tree|
      doc = REXML::Document.new(tree.to_s)
      root = doc.root
      @class_name = root.elements[2].text[1..-2]
      @vm_writer = VMWriter.new(@class_name)
      @symbol_table = SymbolTable.new
      root.elements.each('classVarDec') {|e|
        compile_class_var_dec(e)
      }
      root.elements.each('subroutineDec') {|e|
        #puts e
      }
    }
  end

  def compile_class_var_dec(e) #Compiles a static declaration or a field declaration.
    name = ''
    type = ''
    kind = ''
    state = 0
    e.elements.each{|sub|
      case state
        when 0
          if sub.name == 'keyword' and trim(sub.text) == 'static'
            state = 1
            kind = 'static'
          elsif sub.name == 'keyword' and trim(sub.text) == 'field'
            state = 1
            kind = 'field'
          end
        when 1
          type = trim(sub.text)
          state = 2
        when 2
          name = trim(sub.text)
          @symbol_table.define(name, type, kind)
          state = 3
        when 3
          if trim(sub.text) == ','
            state = 2
          elsif trim(sub.text) == ';'
            state = 0
          end
      end
    }
  end

  def compile_subroutine #Compiles a complete method, function, or constructor.

  end

  def compile_parameter_list #Compiles a (possibly empty) parameter list, not including the enclosing “()”.

  end

  def compile_subroutine_body

  end

  def compile_var_dec #Compiles a var declaration.

  end

  def compile_statements #Compiles a sequence of statements, not including the enclosing “{}”.

  end

  def compile_do #Compiles a do statement.

  end

  def compile_let #Compiles a let statement.

  end

  def compile_while #Compiles a while statement.

  end

  def compile_return #Compiles a return statement.

  end

  def compile_if #Compiles an if statement, possibly with a trailing else clause.

  end

  def compile_expression #Compiles an expression.

  end

  def compile_term #Compiles a term. This routine is faced with a slight difficulty when trying to decide between some of the alternative parsing rules. Specifically, if the current token is an identifier, the routine must distinguish between a variable, an array entry, and a subroutine call. A single look-ahead token, which may be one of “[“, “(“, or “.” suffices to distinguish between the three possibilities. Any other token is not part of this term and should not be advanced over.

  end

  def compile_expression_list #Compiles a (possibly empty) comma-separated list of expressions.

  end

  def trim(str)
    str[1..-2]
  end

  def print_sub_elements(e) #TODO: remove
    e.elements.each{|sub|
      puts sub
    }
  end
end

cg = CodeGeneration.new(ARGV[0])