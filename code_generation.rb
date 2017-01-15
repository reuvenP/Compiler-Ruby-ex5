require './compilation_engine'
require './vm_writer'
require './symbol_table'
require 'rexml/document'

class CodeGeneration
  def initialize(path)
    engine = CompilationEngine.new(path)
    @while_counter = 0
    @if_counter = 0
    @parse_tree_array = engine.get_parse_tree_array
    @parse_tree_array.each {|tree|
      doc = REXML::Document.new(tree.to_s)
      root = doc.root
      @class_name = root.elements[2].text[1..-2]
      @vm_writer = VMWriter.new(@class_name)
      @symbol_table = SymbolTable.new
      vm = ''
      root.elements.each('classVarDec') {|e|
        compile_class_var_dec(e)
      }
      root.elements.each('subroutineDec') {|e|
        vm << compile_subroutine(e)
      }
      puts vm #TODO: write to file
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

  def compile_subroutine(e) #Compiles a complete method, function, or constructor.
    vm = ''
    body = ''
    @symbol_table.start_subroutine
    kind = trim(e.elements[1].text)
    type = trim(e.elements[2].text)
    name = trim(e.elements[3].text)
    if kind == 'method'
      @symbol_table.define('this', @class_name , 'arg')
    end
    e.elements.each('parameterList'){|sub|
      compile_parameter_list(sub)
    }
    e.elements.each('subroutineBody'){|sub|
      body = compile_subroutine_body(sub)
    }
    vars = @symbol_table.var_count('var')
    vm << 'function ' << @class_name << '.' << name << ' ' << vars.to_s << "\n"
    if kind == 'method'
      vm << "push argument 0\npop pointer 0\n" #TODO: check it
    end
    vm << body
    vm
  end

  def compile_parameter_list(e) #Compiles a (possibly empty) parameter list, not including the enclosing “()”.
    if e.elements.count >= 2
      @symbol_table.define(trim(e.elements[2].text),trim(e.elements[1].text), 'arg' )
      i = 3
      while i <= e.elements.count
        @symbol_table.define(trim(e.elements[i + 2].text),trim(e.elements[i + 1].text), 'arg' )
        i += 3
      end
    end
  end

  def compile_subroutine_body(e)
    e.elements.each('varDec'){|sub|
      compile_var_dec(sub)
    }
    vm = ''
    e.elements.each('statements'){|sub|
      vm << compile_statements(sub)
    }
    vm
  end

  def compile_var_dec(e) #Compiles a var declaration.
    name = ''
    type = ''
    kind = ''
    state = 0
    e.elements.each{|sub|
      case state
        when 0
          if sub.name == 'keyword' and trim(sub.text) == 'var'
            state = 1
            kind = 'var'
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

  def compile_statements(e) #Compiles a sequence of statements, not including the enclosing “{}”.
    vm = ''
    e.elements.each{|sub|
      case sub.name
        when 'doStatement'
          vm << compile_do(sub)
        when 'letStatement'
          vm << compile_let(sub)
        when 'whileStatement'
          vm << compile_while(sub)
        when 'returnStatement'
          vm << compile_return(sub)
        when 'ifStatement'
          vm << compile_if(sub)
      end
    }
    vm
  end

  def compile_do(e) #Compiles a do statement.
    do_elem = e.elements[1]
    e.elements.delete do_elem
    vm = compile_subroutine_call(e)
    vm << "pop temp 0\n" #TODO: check it
    vm
  end

  def compile_subroutine_call(e)
    arguments = 0
    e.elements.each('expressionList'){|list|
      list.elements.each('expression'){
        arguments += 1
      }
    }
    vm = ''
    if trim(e.elements[2].text) == '.'
      vm << compile_expression_list(e.elements[5])
      vm << 'call ' << trim(e.elements[1].text) << '.' << trim(e.elements[3].text) << ' ' << arguments.to_s << "\n"
    else
      vm << compile_expression_list(e.elements[3])
      vm << 'call ' << @class_name << '.' << trim(e.elements[1].text) << ' ' << arguments.to_s << "\n"
    end
    vm
  end

  def compile_let(e) #Compiles a let statement.
    #print_sub_elements(e)
    vm = ''
    num_of_expr = 0
    e.elements.each('expression'){
      num_of_expr += 1
    }
    right_side_expression = nil
    left_side_expression = nil
    if num_of_expr == 1 #regular let
      right_side_expression = e.elements[4]
    else #with index
      left_side_expression = e.elements[4]
      right_side_expression = e.elements[7]
    end
    right_side_vm = compile_expression(right_side_expression)
    if left_side_expression == nil
      vm << right_side_vm
      vm << write_var_to_vm(e.elements[2])
    else
      #TODO: imp
    end
    vm
  end

  def compile_while(e) #Compiles a while statement.
    while_counter = @while_counter
    @while_counter += 1
    vm = 'label WHILE_EXP' << while_counter.to_s << "\n"
    vm << compile_expression(e.elements[3])
    vm << "not\n"
    vm << 'if-goto WHILE_END' << while_counter.to_s << "\n"
    vm << compile_statements(e.elements[6])
    vm << 'goto WHILE_EXP' << while_counter.to_s << "\n"
    vm << 'label WHILE_END' << while_counter.to_s << "\n"
    vm
  end

  def compile_return(e) #Compiles a return statement.
    vm = ''
    case e.elements[2].name
      when 'symbol'
        vm << "push constant 0\nreturn\n"
      when 'expression'
        vm << compile_expression(e.elements[2])
        vm << "return\n"
    end
    vm
  end

  def compile_if(e) #Compiles an if statement, possibly with a trailing else clause.
    if_counter = @if_counter
    @if_counter += 1
    stat_counter = 0
    e.elements.each('statements'){
      stat_counter += 1
    }
    vm = compile_expression(e.elements[3])
    vm << 'if-goto IF_TRUE' << if_counter.to_s << "\n"
    vm << 'goto IF_FALSE' << if_counter.to_s << "\n"
    vm << 'label IF_TRUE' << if_counter.to_s << "\n"
    vm << compile_statements(e.elements[6])
    if stat_counter == 1 #if without else
      vm << 'label IF_FALSE' << if_counter.to_s << "\n"
    else
      vm << 'goto IF_END' << if_counter.to_s << "\n"
      vm << 'label IF_FALSE' << if_counter.to_s << "\n"
      vm << compile_statements(e.elements[10])
      vm << 'label IF_END' << if_counter.to_s << "\n"
    end
    vm
  end

  def compile_expression(e) #Compiles an expression.
    num_of_elements = e.elements.count
    vm = compile_term(e.elements[1])
    i = 2
    while i <= num_of_elements
      vm << compile_term(e.elements[i + 1])
      case trim(e.elements[i].text)
        when '+'
          vm << "add\n"
        when '-'
          vm << "sub\n"
        when '*'
          vm << "call Math.multiply 2\n" #TODO: possibly replace with func call
        when '/'
          vm << "call Math.divide 2\n" #TODO: possibly replace with func call
        when '&'
          vm << "and\n"
        when '|'
          vm << "or\n"
        when '<'
          vm << "lt\n"
        when '>'
          vm << "gt\n"
        when '='
          vm << "eq\n"
      end
      i += 2
    end
    vm
  end

  def compile_term(e) #Compiles a term. This routine is faced with a slight difficulty when trying to decide between some of the alternative parsing rules. Specifically, if the current token is an identifier, the routine must distinguish between a variable, an array entry, and a subroutine call. A single look-ahead token, which may be one of “[“, “(“, or “.” suffices to distinguish between the three possibilities. Any other token is not part of this term and should not be advanced over.
    vm = ''
    case e.elements[1].name
      when 'integerConstant'
        vm << 'push constant ' << trim(e.elements[1].text) << "\n"
      when 'stringConstant'
        str = trim(e.elements[1].text)
        len = str.length
        vm << 'push constant ' << len.to_s << "\n"
        vm << "call String.new 1\n"
        i = 0
        while i < len
          ascii = str[i].ord
          vm << 'push constant ' << ascii.to_s << "\n"
          vm << "call String.appendChar 2\n"
          i += 1
        end
      when 'keyword'
        case trim(e.elements[1].text)
          when 'true'
            vm << "push constant 0\nnot\n"
          when 'false'
            vm << "push constant 0\n"
          when 'null'
            vm << "push constant 0\n"
          when 'this'
            vm << "push pointer 0\n"
        end
      when 'symbol'
        case trim(e.elements[1].text)
          when '-'
            vm << compile_term(e.elements[2])
            vm << "neg\n"
          when '~'
            vm << compile_term(e.elements[2])
            vm << "not\n"
          when '('
            vm << compile_expression(e.elements[2])
        end
      when 'identifier'
        if e.elements.count == 1 #simple var
          vm << read_var_to_vm(e.elements[1])
        else
          case trim(e.elements[2].text)
            when '['
              #TODO: imp
            when '('
              #TODO: imp
              vm << compile_subroutine_call(e)
            when '.'
              #TODO: imp
              vm << compile_subroutine_call(e)
          end
        end
    end
    vm
  end

  def read_var_to_vm(e)
    vm = ''
    index = @symbol_table.index_of(trim(e.text))
    kind = @symbol_table.kind_of(trim(e.text))
    type = @symbol_table.type_of(trim(e.text))
    case kind
      when 'arg'
        vm << 'push argument ' << index.to_s << "\n"
      when 'var'
        vm << 'push local ' << index.to_s << "\n"
      when 'static'
        vm << 'push static ' << index.to_s << "\n"
      when 'field'
        vm << 'push this ' << index.to_s << "\n"
    end
    vm
  end

  def write_var_to_vm(e)
    vm = ''
    index = @symbol_table.index_of(trim(e.text))
    kind = @symbol_table.kind_of(trim(e.text))
    type = @symbol_table.type_of(trim(e.text))
    case kind
      when 'arg'
        vm << 'pop argument ' << index.to_s << "\n"
      when 'var'
        vm << 'pop local ' << index.to_s << "\n"
      when 'static'
        vm << 'pop static ' << index.to_s << "\n"
      when 'field'
        vm << 'pop this ' << index.to_s << "\n"
    end
    vm
  end

  def compile_expression_list(e) #Compiles a (possibly empty) comma-separated list of expressions.
    vm = ''
    e.elements.each('expression'){|exp|
      vm << compile_expression(exp)
    }
    vm
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