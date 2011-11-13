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