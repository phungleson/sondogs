require 'rubygems'
require 'rmagick'

image = Magick::Image::read('run.png').first
p image.pixel_color(0, 0, 1)