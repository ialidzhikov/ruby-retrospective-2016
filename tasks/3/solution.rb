class Argument
  attr_reader :name

  def initialize(name, block)
    @name = name
    @block = block
  end

  def execute(command_runner, arg)
    @block.call(command_runner, arg)
  end

  def to_s
    "[#{@name}]"
  end
end

class Option
  attr_reader :short_name, :full_name, :help_text

  def initialize(short_name, full_name, help_text, block)
    @short_name = short_name
    @full_name = full_name
    @help_text = help_text
    @block = block
  end

  def self.option?(arg)
    arg[0] == "-"
  end

  def execute(command_runner, parameter)
    @block.call(command_runner, parameter)
  end

  def to_s
    "-#{@short_name}, --#{@full_name} #{@help_text}"
  end
end

class OptionWithParameter < Option
  attr_reader :placeholder

  def initialize(short_name, full_name, help_text, placeholder, block)
    super(short_name, full_name, help_text, block)
    @placeholder = placeholder
  end

  def extract_parameter(arg)
    start = if arg.start_with?("--")
              "--#{@full_name}="
            else
              "-#{@short_name}"
            end

    arg.sub(start, "")
  end

  def to_s
    "-#{@short_name}, --#{full_name}=#{@placeholder} #{@help_text}"
  end
end

class ArgumentContainer
  attr_reader :arguments

  def initialize
    @current = -1
    @arguments = []
  end

  def add(argument)
    @arguments.push(argument)
  end

  def next
    @current += 1
    @arguments[@current]
  end
end

class OptionContainer
  attr_reader :options

  def initialize
    @options = []
  end

  def add(option)
    @options.push(option)
  end

  def get(arg)
    name = arg.include?("=") ? arg[0...arg.index("=")] : arg.clone

    if name.start_with?("--")
      get_by_full_name(name)
    else
      get_by_short_name(name) || get_starting_with_short_name(name)
    end
  end

  private

  def get_by_short_name(short_name)
    @options.find { |option| "-#{option.short_name}" == short_name }
  end

  def get_by_full_name(full_name)
    @options.find { |option| "--#{option.full_name}" == full_name }
  end

  def get_starting_with_short_name(short_name)
    @options.find { |option| short_name.start_with?("-#{option.short_name}") }
  end
end

class CommandParser
  LINE_SEPARATOR = "\n"
  OPTION_INDENTATION = "    "

  def initialize(command_name)
    @command_name = command_name
    @argument_container = ArgumentContainer.new
    @option_container = OptionContainer.new
  end

  def argument(name, &block)
    argument = Argument.new(name, block)
    @argument_container.add(argument)
  end

  def option(short_name, full_name, help_text, &block)
    option = Option.new(short_name, full_name, help_text, block)
    @option_container.add(option)
  end

  def option_with_parameter(short_name, full_name, help, placeholder, &block)
    option = OptionWithParameter
                .new(short_name, full_name, help, placeholder, block)
    @option_container.add(option)
  end

  def parse(command_runner, argv)
    argv.each { |arg| parse_argument(command_runner, arg) }
  end

  def help
    arguments = @argument_container.arguments.join(" ")
    arguments = " " + arguments if arguments != ""
    option_separator = "#{LINE_SEPARATOR}#{OPTION_INDENTATION}"
    options = @option_container.options.join(option_separator)
    options = option_separator + options if options != ""

    "Usage: #{@command_name}#{arguments}#{options}"
  end

  private

  def parse_argument(command_runner, arg)
    if Option.option?(arg)
      option = @option_container.get(arg)
      parameter = extract_parameter(option, arg)

      option&.execute(command_runner, parameter)
    else
      argument = @argument_container.next
      argument.execute(command_runner, arg)
    end
  end

  def extract_parameter(option, arg)
    if option.is_a? OptionWithParameter
      option.extract_parameter(arg)
    else
      true
    end
  end
end
