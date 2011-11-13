require 'rubygems'
require 'rmagick'
require 'rational'

$image = Magick::Image::read('run.png').first
$width = 640
$height = 359
$sensitivity = 3000

class Magick::Pixel
  # Calculate the color distance between 2 pixels.
  def distance(pixel)
    Math.sqrt((red - pixel.red)**2 + (green - pixel.green)**2 + (blue - pixel.blue)**2)
  end
end

class Array
  # Get the average of an Array.
  def avg
    inject(0.0) { |sum, v| sum += v; sum } / size
  end
end

# Represent a partial of the image.
class Node
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

# Determine where to split the picture.
widths_of_node = {}
distance_pre1 = nil
distance_pre2 = nil
(0..$width - 1).each_with_index do |width, index|
  node_1 = Node.new(:x => 0, :y => 0, :w => width , :h => $height, :index => 1)
  node_2 = Node.new(:x => width, :y => 0, :w => $width - width, :h => $height, :index => 2)

  distance = node_1.distance_to(node_2)

  # Mark the position and the possible width if there is a significant changes in distance.
  # The changes signified by an increase (distance_pre1 - distance_pre2) then decrease (distance_pre1 - distance) in distance.
  if distance_pre1 && distance_pre2 && (distance_pre1 - distance_pre2) > $sensitivity && (distance_pre1 - distance) > $sensitivity
    width_of_node = (width - 1).gcd($width)
    widths_of_node[width_of_node] ||= 0
    widths_of_node[width_of_node] += 1
  end

  distance_pre2 = distance_pre1
  distance_pre1 = distance
end

# Determine the most possible width of nodes (the most frequently appeared width).
p $node_width = widths_of_node.sort_by { |width_of_node, count| count }.last.first
p $nodes_count = $width / $node_width

# Split the picture into nodes based on calculated information, and do the normal routine to re-organize the image
nodes = (0..$nodes_count - 1).map { |index| Node.new(:x => index * $node_width, :y => 0, :w => $node_width, :h => $height, :index => index) }

# Calculate distances between nodes.
nodes.each do |node|
  nodes.each do |n|
    next if n == node
    if n.distances_from[node.index]
      node.distances_to[n.index] = n.distances_from[node.index]
    else
      n.distances_from[node.index] = node.distance_to(n)
    end
  end
end

# Greedily build the result by selecting the node with min distance to/from the current node.
indices = [0]
begin
  index_to, distance_to_min = nodes[indices.last].distances_to.select { |k, v| !indices.include?(k) }.sort_by { |k, v| v }.first
  index_from, distance_from_min = nodes[indices.first].distances_from.select { |k, v| !indices.include?(k) }.sort_by { |k, v| v }.first

  distance_to_min < distance_from_min ? indices << (index = index_to) : indices.insert(0, index = index_from)
end while indices.size < $nodes_count

p indices

# Copy to a new and correct image.
image = Magick::Image.new($width, $height)
indices.each_with_index do |correct_index, index|
  (0..$height - 1).each do |h|
    $image.get_pixels(correct_index * $node_width, h, $node_width, 1).each_with_index do |pixel, i|
      image.pixel_color(index * $node_width + i, h, pixel)
    end
  end
end
image.write('run_correct_bonus.png')