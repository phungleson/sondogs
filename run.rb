require 'rubygems'
require 'rmagick'

$image = Magick::Image::read('run.png').first
$wigth = 640
$height = 359
$node_width = 32
$nodes_count = 20

class Magick::Pixel
  def distance(pixel)
    Math.sqrt((red - pixel.red)**2 + (green - pixel.green)**2 + (blue - pixel.blue)**2)
  end
end

class Array
  def avg
    inject(0.0) { |sum, v| sum += v; sum } / size
  end
end

class Node
  attr_accessor :x, :y, :w, :h, :index

  def initialize(options = {})
    options.each { |k, v| send(:"#{k}=", v) }
  end

  def inspect
    [x, y, w, h].inspect
  end

  def distances_to
    @distances_to ||= {}
  end

  def distances_from
    @distances_from ||= {}
  end

  def distance_to(node)
    unless distances_to[node.index]
      distances_to[node.index] = (0..$height).map do |height|
        distance = $image.pixel_color(x + w - 1, height).distance($image.pixel_color(node.x, height))

        if height < $height
          distance -= $image.pixel_color(x + w - 1, height).distance($image.pixel_color(x + w - 1, height + 1))
          distance -= $image.pixel_color(node.x, height).distance($image.pixel_color(node.x, height + 1))
        end

        distance
      end.avg
    end
    distances_to[node.index]
  end
end

# 640 pixels wide and 359 pixels high
nodes = (0..$nodes_count - 1).map { |index| Node.new(:x => index * $node_width, :y => 0, :w => $node_width, :h => $height, :index => index) }

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

indices = [0]
begin
  index_to, distance_to_min = nodes[indices.last].distances_to.select { |k, v| !indices.include?(k) }.sort_by { |k, v| v }.first
  index_from, distance_from_min = nodes[indices.first].distances_from.select { |k, v| !indices.include?(k) }.sort_by { |k, v| v }.first

  distance_to_min < distance_from_min ? indices << (index = index_to) : indices.insert(0, index = index_from)
end while indices.size < $nodes_count

p indices

image = Magick::Image.new($wigth, $height)
indices.each_with_index do |correct_index, index|
  (0..$height - 1).each do |h|
    $image.get_pixels(correct_index * $node_width, h, $node_width, 1).each_with_index do |pixel, i|
      image.pixel_color(index * $node_width + i, h, pixel)
    end
  end
end
image.write('run_correct.png')