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

  def execute(runner, _)
    @block.call(runner, true)
  end

  def short_prefix
    "-#{@short_name}"
  end

  def long_prefix
    "--#{@full_name}"
  end

  def can_handle?(argument)
    argument == short_prefix || argument == long_prefix
  end

  def to_s
    "    #{short_prefix}, #{long_prefix} #{@help_text}"
  end
end

class OptionWithParameter < Option
  attr_reader :placeholder

  def initialize(short_name, full_name, help_text, placeholder, block)
    super(short_name, full_name, help_text, block)
    @placeholder = placeholder
  end

  def execute(runner, parameter)
    @block.call(runner, extract_parameter(parameter))
  end

  def long_prefix
    "--#{@full_name}="
  end

  def can_handle?(argument)
    argument.start_with?(short_prefix) || argument.start_with?(long_prefix)
  end

  def to_s
    "    #{short_prefix}, #{long_prefix}#{@placeholder} #{@help_text}"
  end

  private

  def extract_parameter(arg)
    if arg.start_with?(short_prefix)
      arg[short_prefix.size..-1]
    elsif arg.start_with?(long_prefix)
      arg[long_prefix.size..-1]
    end
  end
end

class CommandParser
  def initialize(command_name)
    @command_name = command_name
    @arguments = []
    @options = []
  end

  def argument(name, &block)
    @arguments.push(Argument.new(name, block))
  end

  def option(short_name, full_name, help_text, &block)
    @options.push(Option.new(short_name, full_name, help_text, block))
  end

  def option_with_parameter(short_name, full_name, help, placeholder, &block)
    @options.push(
      OptionWithParameter.new(short_name, full_name, help, placeholder, block)
    )
  end

  def parse(runner, argv)
    options = argv.select { |arg| arg.start_with?('-') }
    arguments = argv - options

    options.each do |arg|
      option_for_argument(arg).execute(runner, arg)
    end

    @arguments.zip(arguments) do |handler, value|
      handler.execute(runner, value)
    end
  end

  def help
    help_message = "Usage: #{@command_name}"
    help_message << " #{@arguments.join(' ')}" unless @arguments.empty?
    help_message << "\n#{@options.join("\n")}" unless @options.empty?
    help_message
  end

  private

  def option_for_argument(argument)
    @options.find { |option| option.can_handle?(argument) }
  end
end
