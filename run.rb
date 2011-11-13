#!/usr/bin/env ruby
require 'rubygems'
require 'rational'
require 'rmagick'

require 'ext'
require 'sheet'
require 'shredded_image'

image = ShreddedImage.new('run.png')

image.autodetect if ARGV.include?('with_autodetect')

image.unshred