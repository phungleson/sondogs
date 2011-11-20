class ShreddedImage
  attr_reader :file, :image, :width, :height, :width_of_sheet

  def initialize(file)
    @file = file
    @image = Magick::Image::read(@file).first
    @width = @image.columns
    @height = @image.rows
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

  def autodetect
    sets = []
    distances = {}

    (0..width / 2).each do |x|
      distances[x] ||= distance_between(x, x + 1)

      next if distances.size < 3

      # A cut is signified by an increase (distances[-2] - distances[-1]) then decrease (distances[-1] - distances[0]).
      delta_1 = distances[x - 1] - distances[x - 2]
      delta_2 = distances[x - 1] - distances[x]
      if delta_1 > 0 && delta_2 > 0
        # Don't count if the current x is already calculated.
        next if sets.select { |set_of_cuts| set_of_cuts[x] }.size > 0

        # Calculate all possible cuts, assuming the first cut is at x.
        set_of_cuts = { x => [delta_1, delta_2] }
        cut = x + x

        while cut < width
          distances[cut - 2] ||= distance_between(cut - 2, cut - 1)
          distances[cut - 1] ||= distance_between(cut - 1, cut)
          distances[cut] ||= distance_between(cut, cut + 1)

          d_1 = distances[cut - 1] - distances[cut - 2]
          d_2 = distances[cut - 1] - distances[cut]

          if d_1 > 0 && d_2 > 0
            set_of_cuts[cut] = [d_1, d_2]
            cut += x
          else
            set_of_cuts.nil?
            break
          end
        end

        sets << set_of_cuts if set_of_cuts
      end

    end

    if sets.size > 0
      # The chosen set must have max average of deltas.
      average_highest = 0
      index = 0
      sets.each_with_index do |set_of_cuts, i|
        average_of_deltas = set_of_cuts.map do |cut, deltas|
          deltas
        end.flatten.avg

        p "Set #{i} avg => #{average_of_deltas.to_i} for cuts at: #{set_of_cuts.sort_by { |cut, deltas| cut }.map { |cut, deltas| "#{cut} => [#{deltas[0].to_i}, #{deltas[1].to_i}]" }.join(', ')}"

        if average_highest < average_of_deltas
          average_highest = average_of_deltas
          index = i
        end
      end

      p "Chosen set with the highest average of #{average_highest.to_i} at index #{index}: #{sets[index].sort_by { |cut, deltas| cut }.map { |cut, deltas| cut }.join(', ')}"

      @width_of_sheet = sets[index].keys.sort.first
    else
      p "Failed to auto detect possible cuts."
    end
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