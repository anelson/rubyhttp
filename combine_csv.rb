#!/usr/bin/ruby -w

#Quick and dirty script to combine a bunch of .csv output files from rubyhttp into one, for
#easy importing into Excel

header = nil
lines = []

Dir.glob('*.csv') do |filename|
  #Parse components of the filename to get information that will be prepended to each
  #row within this file when it's output to the aggregate file
  parts = File.basename(filename, File.extname(filename)).split('-')
  next unless parts.length >= 3
  ruby_ver = parts[0]
  platform = parts[1]
  test_variant = parts[2..-1].join('-')

  line_prefix = [ruby_ver, platform, test_variant]

  File.open(filename, 'r') do |file|
    file_header = file.readline.chomp.split(',')
    
    #We assume all the files have the same header.  If this is the first file, save off its header, otherwise
    #just drop it on the floor
    header ||= file_header
    file.each_line do |line|
      line = line_prefix + line.chomp.split(',')
      lines << line
    end
  end
end

#Put the fields extracted from the filename at the front of the header
header = ["ruby_ver", "platform", "test_variant"] + header

print header.join(',')
print "\n"

lines.each do |line|
  print line.join(',')
  print "\n"
end


