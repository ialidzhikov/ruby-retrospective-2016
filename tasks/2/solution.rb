class Integer
  def self.number?(arg)
    arg.to_i.to_s == arg
  end
end

class Hash
  def fetch_deep(path)
    path.split('.').reduce(self) do |memo, key|
      return unless memo
      
      if memo.is_a? Array
        memo[key.to_i] if Integer.number? key
      else
        memo[key] || memo[key.to_sym]
      end
    end
  end

  def reshape(shape)
    shape_copy = clone_deep(shape)
    new_self = reshape_recursive(shape_copy)

    self.replace(new_self)
  end

  private

  def reshape_recursive(shape)
    shape.each do |key, value|
      if value.is_a? Hash
        shape[key] = reshape_recursive(value)
      elsif value.is_a? String
        shape[key] = self.fetch_deep(value)
      end
    end
  end

  def clone_deep(hash)
    new_hash = {}
    hash.each do |key, value|
      new_hash[key] = (value.is_a? Hash) ? clone_deep(value) : value.clone
    end

    new_hash
  end
end

class Array
  def reshape(shape)
    self.each do |e|
      e.reshape(shape)
    end
  end
end