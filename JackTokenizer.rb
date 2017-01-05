
class JackTokenizer

  @token_types = {KEYWORD: 'keyword', SYMBOL: 'symbol', IDENTIFIER: 'identifier', INT_CONST: 'integerConstant', STRING_CONST: 'stringConstant'}


  def initialize(path) #Constructor. Opens the input file/stream and gets ready to tokenize it.
    @symbols = %w|{ } ( ) [ ] . , ; + - * / & \| < > = - |
    @keywords = {CLASS: 'class', METHOD: 'method', FUNCTION: 'function', CONSTRUCTOR: 'constructor',  INT: 'int',
                 BOOLEAN: 'boolean', CHAR: 'char', VOID: 'void', VAR: 'var', STATIC: 'static', FIELD: 'field',
                 LET: 'let', DO: 'do', IF: 'if', ELSE: 'else', WHILE: 'while', RETURN: 'return', TRUE: 'true',
                 FALSE: 'false', NULL: 'null', THIS: 'this'}
    @all_files = Dir.entries(path).select{|f| f.end_with? '.jack'}
    @all_files.each { |file|
      xml_stream = tokenize_file(path + "\\" + file)
      xml_file = file[0..-6]
      xml_file << 'T.xml'
      xml_full_path = path + "\\" + xml_file
      File.open(xml_full_path, 'w') do |f|
        f.puts(xml_stream)
      end
    }
  end

  def tokenize_file(path)
    tokens = Hash.new
    token = ''
    state = 0
    tokens_counter = 0
    stream = File.read(path)
    stream = stream.gsub(/\/\/[^\n]*\n/, '') #remove single-line comment
    stream = stream.gsub(/(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/)/, '') #remove multi-line comment
    stream.each_char do |c|
      case state
        when 0
          if c =~ /[0-9]/
            state = 3
            token = c
          elsif c == "\""
            state = 5
            token = ''
          elsif @symbols.include? c
            state = 0
            tokens[[tokens_counter, 0]] = 'symbol'
            tokens[[tokens_counter, 1]] = c
            tokens_counter += 1
          elsif c == '_'
            state = 2
            token = c
          elsif c =~ /[A-Za-z]/
            state = 12
            token = c
          else
            state = 0
          end
        when 3
          if c =~ /[0-9]/
            state = 3
            token << c
          else
            state = 0
            tokens[[tokens_counter, 0]] = 'integerConstant'
            tokens[[tokens_counter, 1]] = token
            tokens_counter += 1
            token = ''
            if @symbols.include? c
              tokens[[tokens_counter, 0]] = 'symbol'
              tokens[[tokens_counter, 1]] = c
              tokens_counter += 1
            end
          end
        when 5
          if c == "\""
            state = 0
            tokens[[tokens_counter, 0]] = 'stringConstant'
            tokens[[tokens_counter, 1]] = token
            tokens_counter += 1
            token = ''
          else
            state = 5
            token << c
          end
        when 2
          if c =~ /[a-zA-Z0-9_]/
            state = 2
            token << c
          else
            state = 0
            tokens[[tokens_counter, 0]] = 'identifier'
            tokens[[tokens_counter, 1]] = token
            tokens_counter += 1
            token = ''
            if @symbols.include? c
              tokens[[tokens_counter, 0]] = 'symbol'
              tokens[[tokens_counter, 1]] = c
              tokens_counter += 1
            end
          end
        when 12
          if c =~ /[0-9_]/
            state = 2
            token << c
          elsif c =~ /[a-zA-Z]/
            state = 12
            token << c
          else
            state = 0
            if @keywords.values.include? token
              tokens[[tokens_counter, 0]] = 'keyword'
            else
              tokens[[tokens_counter, 0]] = 'identifier'
            end
            tokens[[tokens_counter, 1]] = token
            tokens_counter += 1
            token = ''
            if @symbols.include? c
              tokens[[tokens_counter, 0]] = 'symbol'
              tokens[[tokens_counter, 1]] = c
              tokens_counter += 1
            end
          end
        else
      end
    end
    tokens_to_xml(tokens, tokens_counter)
  end

  def tokens_to_xml(tokens, len)
    xml = "<tokens>\n"
    i = 0
    while i < len do
      xml << '<' << tokens[[i, 0]] << '> '
      if tokens[[i, 0]] == 'symbol'
        case tokens[[i, 1]]
          when '<'
            xml << '&lt;'
          when '>'
            xml << '&gt;'
          when '&'
            xml << '&amp;'
          when "\""
            xml << '&quot;'
          else
            xml << tokens[[i, 1]]
        end
      else
        xml << tokens[[i, 1]]
      end
      xml << ' </' << tokens[[i, 0]] << ">\n"
      i += 1
    end
    xml << '</tokens>'
    
  end
end
