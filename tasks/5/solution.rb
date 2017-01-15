module Store
  private

  def next_id
    begin
      @sequence += 1
    end until find(id: @sequence)

    @sequence
  end

  def matches?(record, query)
    query.all? do |key, value|
      record[key] == value
    end
  end
end

class ArrayStore
  include Store
  attr_reader :storage

  def initialize
    @sequence = 0
    @storage = []
  end

  def create(record)
    id = record[:id] || next_id
    record[:id] = id
    @storage.push(record)
    record
  end

  def find(query)
    @storage.select do |record|
      matches?(record, query)
    end
  end

  def update(id, record)
    index = @storage.index { |record| record[:id] == id }
    @storage[index].merge!(record)
  end

  def delete(query)
    @storage.delete_if do |record|
      matches?(record, query)
    end
  end
end

class HashStore
  include Store
  attr_reader :storage

  def initialize
    @sequence = 0
    @storage = {}
  end

  def create(record)
    id = record[:id] || next_id
    record[:id] = id
    @storage[id] = record
  end

  def find(query)
    @storage.values.select do |record|
      matches?(record, query)
    end
  end

  def update(id, record)
    @storage[id].merge!(record)
  end

  def delete(query)
    @storage.delete_if do |_, record|
      matches?(record, query)
    end
  end
end

module Model
  def attributes(*attributes)
    return @attributes if attributes.empty?

    init_attributes(attributes)
  end

  def data_store(*args)
    return @data_store if args.empty?

    @data_store = args[0]
  end

  def where(query)
    query.each do |key, _|
      unless (attributes.include? key) || key == :id
        raise DataModel::UnknownAttributeError.new("Unknown attribute #{key}")
      end
    end

    @data_store.find(query).map { |record| new(record) }
  end

  private

  def init_attributes(attributes)
    @attributes = attributes
    attributes.each do |attribute|
      class_eval { attr_accessor attribute }
      define_singleton_method "find_by_#{attribute}" do |value|
        @data_store.find(attribute => value).map { |record| new(record) }
      end
    end
  end
end

class DataModel
  extend Model
  class DeleteUnsavedRecordError < StandardError
  end

  class UnknownAttributeError < StandardError
  end

  attr_reader :id

  def initialize(attributes = {})
    attributes.each do |key, value|
      instance_variable_set('@' + key.to_s, value) if self.respond_to? key
    end
  end

  def ==(other)
    return false if other.nil?

    if !(@id.nil? && other.id.nil?)
      @id == other.id
    else
      object_id == other.object_id
    end
  end

  def save
    if @id.nil?
      record = self.class.data_store.create(to_hash)
      @id = record[:id]
      self
    else
      self.class.data_store.update(@id, to_hash)
    end
  end

  def delete
    raise DeleteUnsavedRecordError.new if @id.nil?

    self.class.data_store.delete(id: @id)
  end

  private

  def to_hash
    hash = {id: @id}
    self.class.attributes.each do |attr|
      hash[attr] = self.public_send(attr)
    end

    hash
  end
end
