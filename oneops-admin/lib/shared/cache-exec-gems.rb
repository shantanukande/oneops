#!/usr/bin/env ruby
require 'optparse'
require 'yaml'
require 'fileutils'
require 'bundler'
Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'exec-order','*.rb')].each {|f| require f }

# set cwd to shared/cookbooks directory
Dir.chdir File.expand_path('cookbooks',File.dirname(__FILE__))

if File.directory? 'vendor'
  puts 'removing vendor directory'
  FileUtils.rm_r 'vendor'
end

Dir.glob('*.gemfile').each do |f|

  if !f.include? '12.11.18'
    puts "packaging gemfile #{f}"

    start_time = Time.now.to_i
    cmd = "bundle package --no-install --no-prune --all --gemfile #{f}"
    ec = system cmd
    if !ec || ec.nil?
      puts "#{cmd} failed with, #{$?}"
      exit 1
    end

    puts "#{cmd} took: #{Time.now.to_i - start_time} sec"
  end
end

#TODO: find if there any better alternatives
puts 'validating whether all gems are present in vendor/cache or not'
Dir.glob('*.gemfile.lock').each do |f|
  puts "finding gems for #{f}"
  lockfile = Bundler::LockfileParser.new(Bundler.read_file(f))
  cache_dir = File.join(File.dirname(f), '/vendor/cache/')

  lockfile.specs.each do |s|
    if s.source.is_a?(Bundler::Source::Path)
      gem_dir = File.basename(s.source.path)
    else
      gem_dir = ''
    end
    gem_path = File.join(cache_dir, gem_dir, "#{s.full_name}.gem")

    if !File.file?(gem_path)
      puts "#{gem_path} not found"
      exit 1
    end
  end
  puts 'all gems present in cache'
end
