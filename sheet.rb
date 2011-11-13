class Sheet
  attr_accessor :x, :y, :w, :h, :index

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

  # Calculate distance to another node.
  # Distance = color distance between 2 vertical lines of pixels - changes in color along the 2 lines.
  def distance_to(node)
    unless distances_to[node.index]
      distances_to[node.index] = (0..$height).map do |height|
        # Color distance between the line on the left (of this node) and the line on the right (of another node).
        distance = $image.pixel_color(x + w - 1, height).distance($image.pixel_color(node.x, height))

        if height < $height
          # Minus the changes of color in the line on the left.
          distance -= $image.pixel_color(x + w - 1, height).distance($image.pixel_color(x + w - 1, height + 1))
          # Minus the changes of color in the line on the right.
          distance -= $image.pixel_color(node.x, height).distance($image.pixel_color(node.x, height + 1))
        end

        distance
      end.avg
    end
    distances_to[node.index]
  end
end