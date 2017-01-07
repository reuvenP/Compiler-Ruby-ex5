class VMWriter
  def initialize
    @vm_output = ''
  end

  #params: segment: CONST, ARG, LOCAL, STATIC, THIS, THAT, POINTER, TEMP. index: int
  def write_push(segment, index) #Writes a VM push command

  end

  #params: segment: CONST, ARG, LOCAL, STATIC, THIS, THAT, POINTER, TEMP. index: int
  def write_pop(segment, index) #Writes a VM pop command

  end

  #params: command: ADD, SUB, NEG, EQ, GT, LT, AND, OR, NOT
  def write_arithmetic(command) #Writes a VM arithmetic command

  end

  #params: label: string
  def write_label(label) #Writes a VM label command

  end

  #params: label: string
  def write_goto(label) #Writes a VM goto command

  end

  #params: label: string
  def write_if(label) #Writes a VM if-goto command

  end

  #params: name: string. n_args: int
  def write_call(name, n_args) #Writes a VM call command

  end

  #params: name: string. n_locals: int
  def write_function(name, n_locals) #Writes a VM function command

  end

  def write_return #Writes a VM return command

  end

  def close #Closes the output file

  end
end