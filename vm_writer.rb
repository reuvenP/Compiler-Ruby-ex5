class VMWriter
  def initialize(class_name)
    @vm_output = ''
    @class_name = class_name
  end

  #params: segment: CONST, ARG, LOCAL, STATIC, THIS, THAT, POINTER, TEMP. index: int
  def write_push(segment, index) #Writes a VM push command
    @vm_output << 'push ' << segment << ' ' << index << "\n"
  end

  #params: segment: CONST, ARG, LOCAL, STATIC, THIS, THAT, POINTER, TEMP. index: int
  def write_pop(segment, index) #Writes a VM pop command
    @vm_output << 'pop ' << segment << ' ' << index << "\n"
  end

  #params: command: ADD, SUB, NEG, EQ, GT, LT, AND, OR, NOT
  def write_arithmetic(command) #Writes a VM arithmetic command
    @vm_output << command << "\n"
  end

  #params: label: string
  def write_label(label) #Writes a VM label command
    @vm_output << 'label ' << label << "\n"
  end

  #params: label: string
  def write_goto(label) #Writes a VM goto command
    @vm_output << 'goto ' << label << "\n"
  end

  #params: label: string
  def write_if(label) #Writes a VM if-goto command
    @vm_output << 'if-goto ' << label << "\n"
  end

  #params: name: string. n_args: int
  def write_call(name, n_args) #Writes a VM call command
    @vm_output << 'call ' << @class_name << '.' << name << ' ' << n_args << "\n"
  end

  #params: name: string. n_locals: int
  def write_function(name, n_locals) #Writes a VM function command
    @vm_output << 'function ' << @class_name << '.' << name << ' ' << n_locals << "\n"
  end

  def write_return #Writes a VM return command
    @vm_output << "return\n"
  end

  def close(path) #Closes the output file
    full_path = path << "\\" << @class_name << '.vm'
    File.open(full_path, 'w') do |f|
      f.puts(@vm_output)
    end
  end
end