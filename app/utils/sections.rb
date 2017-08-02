class Section
  @storage = {}

  def self.set(label, value)
    @storage[label] = value
  end

  def self.get(label)
    @storage[label]
  end
end