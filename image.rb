class Image
  attr_reader :file, :image, :width, :height, :sensitivity, :width_of_sheet

  def initialize(file)
    @file = file
    @image = Magick::Image::read(@file).first
    @width = @image.columns
    @height = @image.rows
    @sensitivity = 3000
    @width_of_sheet = 32 # default value
  end

  # Distance = color distance between 2 vertical lines of pixels - changes in color along the 2 lines.
  def distance_between(x1, x2)
    (0..height).map do |h|
      distance = image.pixel_color(x1, h).distance(image.pixel_color(x2, h))

      if h < height
        # Minus the changes of the pixels below.
        distance -= image.pixel_color(x1, h).distance(image.pixel_color(x1, h + 1))
        distance -= image.pixel_color(x2, h).distance(image.pixel_color(x2, h + 1))
      end

      distance
    end.avg
  end

  def unshred
    x = 0
    sheets = []
    begin
      sheets << Sheet.new(:mirage => self, :x => x, :y => 0, :w => width_of_sheet, :h => height, :index => sheets.size)
      x += width_of_sheet
    end while (x < width)

    # Calculate distances between sheets.
    sheets.each do |sheet1|
      sheets.each do |sheet2|
        next if sheet2 == sheet1
        sheet1.distances_to[sheet2.index] = sheet2.distances_from[sheet1.index] ||= sheet1.get_distance_to(sheet2)
      end
    end

    # Greedily build the result by selecting the sheet with min distance to/from the current sheets.
    indices = [0]
    begin
      index_to, distance_to_min = sheets[indices.last].distances_to.select do |k, v|
        !indices.include?(k)
      end.sort_by { |k, v| v }.first

      index_from, distance_from_min = sheets[indices.first].distances_from.select do |k, v|
        !indices.include?(k)
      end.sort_by { |k, v| v }.first

      if distance_to_min < distance_from_min
        indices << (index = index_to)
      else
        indices.insert(0, index = index_from)
      end
    end while indices.size * width_of_sheet < width

    # Copy to a new and unsheded image.
    unshredded_image = Magick::Image.new(width, height)
    indices.each_with_index do |correct_index, index|
      (0..height - 1).each do |h|
        image.get_pixels(correct_index * width_of_sheet, h, width_of_sheet, 1).each_with_index do |pixel, i|
          unshredded_image.pixel_color(index * width_of_sheet + i, h, pixel)
        end
      end
    end

    unshredded_image.write("unshredded_#{file}")
  end
end