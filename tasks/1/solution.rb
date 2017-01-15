class Substance
  attr_reader :name
  attr_reader :melting_point
  attr_reader :boiling_point

  def initialize(name, melting_point, boiling_point)
    @name = name
    @melting_point = melting_point
    @boiling_point = boiling_point
  end
end

SUBSTANCES = {
  'water' => Substance.new('water', 0, 100),
  'ethanol' => Substance.new('ethanol', -114, 78.37),
  'gold' => Substance.new('gold', 1064, 2700),
  'silver' => Substance.new('silver', 961.8, 2162),
  'copper' => Substance.new('cooper', 1085, 2567)
}

def convert_between_temperature_units(degrees, from, to)
  celsius = convert_to_celsius_from(degrees, from)
  convert_from_celsius_to(celsius, to)
end

def convert_to_celsius_from(degrees, unit)
  case unit
  when 'C'
    degrees
  when 'F'
    (degrees - 32) * 5 / 9.0
  when 'K'
    degrees - 273.15
  else
    raise ArgumentError.new("Unknown temperature unit #{unit}.")
  end
end

def convert_from_celsius_to(degrees, unit)
  case unit
  when 'C'
    degrees
  when 'F'
    (degrees * 9 / 5.0) + 32
  when 'K'
    degrees + 273.15
  else
    raise ArgumentError.new("Unknown temperature unit #{unit}.")
  end
end

def melting_point_of_substance(substance, unit)
  unless SUBSTANCES.key?(substance)
    raise ArgumentError.new("Unknown substance #{substance}.")
  end

  convert_from_celsius_to(SUBSTANCES[substance].melting_point, unit)
end

def boiling_point_of_substance(substance, unit)
  unless SUBSTANCES.key?(substance)
    raise ArgumentError.new("Unknown substance #{substance}.")
  end
  
  convert_from_celsius_to(SUBSTANCES[substance].boiling_point, unit)
end