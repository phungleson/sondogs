class Sheet
  attr_accessor :x, :y, :w, :h, :index, :mirage

  def initialize(options = {})
    options.each { |k, v| send(:"#{k}=", v) }
  end

  def inspect
    [x, y, w, h].inspect
  end

  # List of all distances to other nodes.
  def distances_to
    @distances_to ||= {}
  end

  # List of all distances from other nodes.
  def distances_from
    @distances_from ||= {}
  end

  # Calculate distance to another sheet.
  def get_distance_to(sheet)
    distances_to[node.index] ||= sheet.distance_between(x + w - 1, sheet.x)
  end
end