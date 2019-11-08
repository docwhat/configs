#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'

Dir.chdir File.dirname(__FILE__)

START_MARKER = '### INCLUDE BEGIN'.freeze
STOP_MARKER = '### INCLUDE FINISH'.freeze

INCLUDE_YAML = [
  START_MARKER,
  Dir['include/*.yaml']
    .map { |x| Pathname.new x }
    .sort
    .map(&:read),
  STOP_MARKER
].join("\n\n").freeze

ARGV.each do |raw_path|
  path = Pathname.new raw_path

  content = path.read

  path.write(
    content
      .gsub(/{{file\.Read[^}]+}}/, "#{START_MARKER}\n\n#{STOP_MARKER}")
      .gsub(/#{START_MARKER}.*#{STOP_MARKER}/m, INCLUDE_YAML)
  )
end
