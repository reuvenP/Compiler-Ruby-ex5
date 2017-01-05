require './JackTokenizer'
require 'rexml/document'

class CompilationEngine

  def initialize(path)
    JackTokenizer.new(path)
    @all_files = Dir.entries(path).select{|f| f.end_with? 'T.xml'}
    @string_counter = 0
    @string_array = Array.new
    @all_files.each {|file|
      @tokens_array = []
      @parse_tree = []
      tokens_stream = File.read(path + "\\" + file)
      doc = REXML::Document.new(tokens_stream)
      root = doc.root
      root.elements.each {|token|
        elem = [token.name, token.text[1..-2]]
        if elem[0] == 'stringConstant'
          @string_array.push(elem[1])
          elem[1] = @string_counter
          @string_counter += 1
        end
        @tokens_array.push(elem)
      }
      tree = compile_class
      doc = REXML::Document.new
      doc.add(tree)
      doc.write(str='', 2)
      #prettify keyword
      str = str.gsub(/<keyword>\r\s*/, '<keyword> ')
      str = str.gsub(/<keyword>\n\s*/, '<keyword> ')
      str = str.gsub(/\n\s*<\/keyword>/, '</keyword>')
      str = str.gsub(/\r\s*<\/keyword>/, '</keyword>')
      #prettify identifier
      str = str.gsub(/<identifier>\r\s*/, '<identifier> ')
      str = str.gsub(/<identifier>\n\s*/, '<identifier> ')
      str = str.gsub(/\n\s*<\/identifier>/, '</identifier>')
      str = str.gsub(/\r\s*<\/identifier>/, '</identifier>')
      #prettify symbol
      str = str.gsub(/<symbol>\r\s*/, '<symbol> ')
      str = str.gsub(/<symbol>\n\s*/, '<symbol> ')
      str = str.gsub(/\n\s*<\/symbol>/, '</symbol>')
      str = str.gsub(/\r\s*<\/symbol>/, '</symbol>')
      #prettify integerConstant
      str = str.gsub(/<integerConstant>\r\s*/, '<integerConstant> ')
      str = str.gsub(/<integerConstant>\n\s*/, '<integerConstant> ')
      str = str.gsub(/\n\s*<\/integerConstant>/, '</integerConstant>')
      str = str.gsub(/\r\s*<\/integerConstant>/, '</integerConstant>')
      #prettify stringConstant
      str = str.gsub(/<stringConstant>\r\s*/, '<stringConstant> ')
      str = str.gsub(/<stringConstant>\n\s*/, '<stringConstant> ')
      str = str.gsub(/\n\s*<\/stringConstant>/, '</stringConstant>')
      str = str.gsub(/\r\s*<\/stringConstant>/, '</stringConstant>')
      #prettify parameterList
      str = str.gsub('<parameterList/>', "<parameterList>\n</parameterList>")
      #prettify expressionList
      str = str.gsub('<expressionList/>', "<expressionList>\n</expressionList>")
      arr = str.split(/\n+/)
      i = 0
      while i < arr.length
        if arr[i].include? '</parameterList>' and arr[i-1].include? '<parameterList>'
          leading_spaces = arr[i-1].count(' ')
          arr[i] = ' ' * leading_spaces + arr[i]
        end
        if arr[i].include? '</expressionList>' and arr[i-1].include? '<expressionList>'
          leading_spaces = arr[i-1].count(' ')
          arr[i] = ' ' * leading_spaces + arr[i]
        end
        if arr[i].include? 'stringConstant'
          start_offset = arr[i].index('>') + 2
          end_offset = arr[i].index('</') - 2
          index = arr[i][start_offset..end_offset]
          arr[i] = arr[i].gsub(/[0-9]+/, @string_array[index.to_i])
        end
        i += 1
      end
      out_file = path + "\\" + file[0..-6] + '.xml'
      File.open(out_file, 'w') do |f|
        f.puts(arr)
      end
    }
  end

  def next_token
    if @tokens_array.empty?
      nil
    else
      @tokens_array[0]
    end
  end

  def get_next_token
    if next_token == nil
      nil
    else
      @tokens_array.shift
    end
  end

  def get_next_token_element
    cur = get_next_token
    elem = REXML::Element.new(cur[0])
    elem.text = ' ' << cur[1].to_s << ' '
    elem
  end

  def compile_class #Compiles a complete class.
    base = REXML::Element.new('class')
    base.add_element(get_next_token_element) #'class'
    base.add(get_next_token_element) #className
    base.add(get_next_token_element) #'{'
    while next_token[1] == 'static' or next_token[1] == 'field' #classVarDec*
      base.add(compile_class_var_dec)
    end
    while next_token[1] == 'constructor' or next_token[1] == 'function' or next_token[1] == 'method' #subroutineDec*
      base.add(compile_subroutine)
    end
    base.add(get_next_token_element) #'}'
    base
  end

  def compile_class_var_dec #Compiles a static declaration or a field declaration.
    base = REXML::Element.new('classVarDec')
    base.add(get_next_token_element) #('static' | 'field')
    base.add(get_next_token_element) #type
    base.add(get_next_token_element) #varName
    while next_token[1] == ',' #(',' varName)*
      base.add(get_next_token_element) #','
      base.add(get_next_token_element) #varName
    end
    base.add(get_next_token_element) #';'
    base
  end

  def compile_subroutine #Compiles a complete method, function, or constructor.
    base = REXML::Element.new('subroutineDec')
    base.add(get_next_token_element) #('constructor' | 'function' | 'method')
    base.add(get_next_token_element) #('void' | type)
    base.add(get_next_token_element) #subroutineName
    base.add(get_next_token_element) #'('
    base.add(compile_parameter_list) #parameterList
    base.add(get_next_token_element) #')'
    base.add(compile_subroutine_body) #subroutineBody
    base
  end

  def compile_parameter_list #Compiles a (possibly empty) parameter list, not including the enclosing “()”.
    base = REXML::Element.new('parameterList')
    if next_token[1] != ')' #param list not empty
      base.add(get_next_token_element) #type
      base.add(get_next_token_element) #varName
      while next_token[1] == ','
        base.add(get_next_token_element) #','
        base.add(get_next_token_element) #type
        base.add(get_next_token_element) #varName
      end
    end
    base
  end

  def compile_subroutine_body
    base = REXML::Element.new('subroutineBody')
    base.add(get_next_token_element) #'{'
    while next_token[1] == 'var' #varDec*
      base.add(compile_var_dec)
    end
    base.add(compile_statements) #statements
    base.add(get_next_token_element) #'}'
    base
  end

  def compile_var_dec #Compiles a var declaration.
    base = REXML::Element.new('varDec')
    base.add(get_next_token_element) #'var'
    base.add(get_next_token_element) #type
    base.add(get_next_token_element) #varName
    while next_token[1] == ','
      base.add(get_next_token_element) #,
      base.add(get_next_token_element) #varName
    end
    base.add(get_next_token_element) #';'
    base
  end

  def compile_statements #Compiles a sequence of statements, not including the enclosing “{}”.
    base = REXML::Element.new('statements')
    while next_token[1] == 'let' or next_token[1] == 'if' or next_token[1] == 'while' or next_token[1] == 'do' or next_token[1] == 'return'
      case next_token[1]
        when 'let'
          base.add(compile_let)
        when 'if'
          base.add(compile_if)
        when 'while'
          base.add(compile_while)
        when 'do'
          base.add(compile_do)
        when 'return'
          base.add(compile_return)
        else
      end
    end
    base
  end

  def compile_do #Compiles a do statement.
    base = REXML::Element.new('doStatement')
    base.add(get_next_token_element) #'do'
    base.add(get_next_token_element) #subroutineName | ( className | varName)
    if next_token[1] == '.'
      base.add(get_next_token_element) #'.'
      base.add(get_next_token_element) #'subroutineName'
    end
    base.add(get_next_token_element) #'('
    base.add(compile_expression_list) #expressionList
    base.add(get_next_token_element) #')'
    base.add(get_next_token_element) #';'
    base
  end

  def compile_let #Compiles a let statement.
    base = REXML::Element.new('letStatement')
    base.add(get_next_token_element) #'let'
    base.add(get_next_token_element) #varName
    if next_token[1] == '['
      base.add(get_next_token_element) #'['
      base.add(compile_expression) #expression
      base.add(get_next_token_element) #']'
    end
    base.add(get_next_token_element) #'='
    base.add(compile_expression) #expression
    base.add(get_next_token_element) #';'
    base
  end

  def compile_while #Compiles a while statement.
    base = REXML::Element.new('whileStatement')
    base.add(get_next_token_element) #'while'
    base.add(get_next_token_element) #'('
    base.add(compile_expression) #expression
    base.add(get_next_token_element) #')'
    base.add(get_next_token_element) #'{'
    base.add(compile_statements) #statements
    base.add(get_next_token_element) #'}'
    base
  end

  def compile_return #Compiles a return statement.
    base = REXML::Element.new('returnStatement')
    base.add(get_next_token_element) #'return'
    if next_token[1] != ';'
      base.add(compile_expression) #expression?
    end
    base.add(get_next_token_element) #';'
    base
  end

  def compile_if #Compiles an if statement, possibly with a trailing else clause.
    base = REXML::Element.new('ifStatement')
    base.add(get_next_token_element) #'if'
    base.add(get_next_token_element) #'('
    base.add(compile_expression) #expression
    base.add(get_next_token_element) #')'
    base.add(get_next_token_element) #'{'
    base.add(compile_statements) #statements
    base.add(get_next_token_element) #'}'
    if next_token[1] == 'else'
      base.add(get_next_token_element) #'else'
      base.add(get_next_token_element) #'{'
      base.add(compile_statements) #statements
      base.add(get_next_token_element) #'}'
    end
    base
  end

  def compile_expression #Compiles an expression.
    base = REXML::Element.new('expression')
    base.add(compile_term) #term
    while next_token[1] == '+' or next_token[1] == '-' or next_token[1] == '*' or next_token[1] == '/' or next_token[1] == '&' or next_token[1] == '|' or next_token[1] == '<' or next_token[1] == '>' or next_token[1] == '='
      base.add(get_next_token_element) #op
      base.add(compile_term) #term
    end
    base
  end

  def compile_term #Compiles a term. This routine is faced with a slight difficulty when trying to decide between some of the alternative parsing rules. Specifically, if the current token is an identifier, the routine must distinguish between a variable, an array entry, and a subroutine call. A single look-ahead token, which may be one of “[“, “(“, or “.” suffices to distinguish between the three possibilities. Any other token is not part of this term and should not be advanced over.
    base = REXML::Element.new('term')
    if next_token[0] == 'integerConstant' or next_token[0] == 'stringConstant' or next_token[1] == 'true' or next_token[1] == 'false' or next_token[1] == 'null' or next_token[1] == 'this'
      base.add(get_next_token_element) #integerConstant | stringConstant | keywordConstant
    elsif next_token[1] == '-' or next_token[1] == '~'
      base.add(get_next_token_element) #unaryOp
      base.add(compile_term) #term
    elsif next_token[1] == '('
      base.add(get_next_token_element) #'('
      base.add(compile_expression) #expression
      base.add(get_next_token_element) #')'
    else
      base.add(get_next_token_element) #for lookahead 2 - need to pop the first lookahead
      if next_token[1] == '['
        base.add(get_next_token_element) #'['
        base.add(compile_expression) #expression
        base.add(get_next_token_element) #']'
      elsif next_token[1] == '('
        base.add(get_next_token_element) #'('
        base.add(compile_expression_list) #expressionList
        base.add(get_next_token_element) #')'
      elsif next_token[1] == '.'
        base.add(get_next_token_element) #'.'
        base.add(get_next_token_element) #subroutineName
        base.add(get_next_token_element) #'('
        base.add(compile_expression_list) #expressionList
        base.add(get_next_token_element) #')'
      end
    end
    base
  end

  def compile_expression_list #Compiles a (possibly empty) comma-separated list of expressions.
    base = REXML::Element.new('expressionList')
    if next_token[1] != ')'
      base.add(compile_expression) #expression
      while next_token[1] == ','
        base.add(get_next_token_element) #','
        base.add(compile_expression) #expression
      end
    end
    base
  end

end

CompilationEngine.new(ARGV[0])