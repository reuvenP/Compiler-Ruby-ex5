class SymbolTable
  def initialize #Creates a new empty symbol table
    @symbol_table = Hash.new
    @static_counter = 0
    @field_counter = 0
  end

  def start_subroutine #Stars a new subroutine scope (i.e. resets the subroutine's symbol table)
    @subroutine_table = Hash.new
    @argument_counter = 0
    @var_counter = 0
  end

  #params: name: string, type: string, kind: STATIC, FIELD ARG, VAR
  def define(name, type, kind) #Defines a new identifier for a given name, type and kind and assign it running index. STATIC and FIELD identifiers have a class scope, while ARG and VAR identifiers have a subroutine scope.
    case kind
      when 'static'
        @symbol_table.push([@static_counter, ])
    end
  end

  #params: kind: STATIC, FIELD ARG, VAR
  def var_count(kind) #Returns the number of variables of the given kind already defined in the current scope.

  end


  def kind_of(name)

  end

  def type_of(name)

  end

  def index_of(name)

  end
end