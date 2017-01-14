class SymbolTable
  def initialize #Creates a new empty symbol table
    @symbol_table = Array.new
    @static_counter = 0
    @field_counter = 0
    @subroutine_table = Array.new
    @argument_counter = 0
    @var_counter = 0
  end

  def start_subroutine #Stars a new subroutine scope (i.e. resets the subroutine's symbol table)
    @subroutine_table = Array.new
    @argument_counter = 0
    @var_counter = 0
  end

  #params: name: string, type: string, kind: STATIC, FIELD ARG, VAR
  def define(name, type, kind) #Defines a new identifier for a given name, type and kind and assign it running index. STATIC and FIELD identifiers have a class scope, while ARG and VAR identifiers have a subroutine scope.
    case kind
      when 'static'
        @symbol_table.push([name, type, kind, @static_counter])
        @static_counter += 1
      when 'field'
        @symbol_table.push([name, type, kind, @field_counter])
        @field_counter += 1
      when 'arg'
        @subroutine_table.push([name, type, kind, @argument_counter])
        @argument_counter += 1
      when 'var'
        @subroutine_table.push([name, type, kind, @var_counter])
        @var_counter += 1
      else
    end
  end

  #params: kind: STATIC, FIELD ARG, VAR
  def var_count(kind) #Returns the number of variables of the given kind already defined in the current scope.
    case kind
      when 'static'
        return @static_counter
      when 'field'
        return @field_counter
      when 'arg'
        return @argument_counter
      when 'var'
        return @var_counter
      else
    end
  end


  def kind_of(name)
    i = 0
    while i < @subroutine_table.length
      if @subroutine_table[i][0] == name
        return @subroutine_table[i][2]
      end
      i += 1
    end
    i = 0
    while i < @symbol_table.length
      if @symbol_table[i][0] == name
        return @symbol_table[i][2]
      end
      i += 1
    end
    'none'
  end

  def type_of(name)
    i = 0
    while i < @subroutine_table.length
      if @subroutine_table[i][0] == name
        return @subroutine_table[i][1]
      end
      i += 1
    end
    i = 0
    while i < @symbol_table.length
      if @symbol_table[i][0] == name
        return @symbol_table[i][1]
      end
      i += 1
    end
    'none'
  end

  def index_of(name)
    i = 0
    while i < @subroutine_table.length
      if @subroutine_table[i][0] == name
        return @subroutine_table[i][3]
      end
      i += 1
    end
    i = 0
    while i < @symbol_table.length
      if @symbol_table[i][0] == name
        return @symbol_table[i][3]
      end
      i += 1
    end
    -1
  end

  def print_table #TODO: remove
    puts @symbol_table.to_s
    puts @subroutine_table.to_s
  end
end