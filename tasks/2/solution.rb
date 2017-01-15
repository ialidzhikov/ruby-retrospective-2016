class Hash
  def fetch_deep(path)
    key, nested_path = path.split('.', 2)
    value = self[key] || self[key.to_sym]

    return value unless nested_path

    value.fetch_deep(nested_path) if value
  end

  def reshape(shape)
    return fetch_deep(shape) if shape.is_a? String

    shape.map do |key, value|
      [key, reshape(value)]
    end.to_h
  end
end

class Array
  def reshape(shape)
    map { |e| e.reshape(shape) }
  end

  def fetch_deep(path)
    key, nested_path = path.split('.', 2)
    element = self[key.to_i]

    element.fetch_deep(nested_path) if element
  end
end
