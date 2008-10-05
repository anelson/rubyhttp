#!/usr/bin/ruby -w

#Quick and dirty script to combine a bunch of .csv output files from rubyhttp into one, for
#easy importing into Excel
#
# The end result is a csv file containing a table of values like so:
#
#         site1  site2   site3 site4 site5
# libcurl 
# rfuzz
# stock
# custom1
# custom2
#
# where the table is filled out with %CPU usage values

SITE_NAME_COLUMN = "Site"
IMPL_NAME_COLUMN = "Impl"
NET_HTTP_IMPL_NAME = "net/http"
TOTAL_CPU_TIME_COLUMN = "Total CPU Time"
CLOCK_TIME_COLUMN = "Clock Time"

def avg(values)
  return 0 if values == nil

  total = 0
  values.each { |val| total += val}

  total / values.length
end

data = {}

sites = []

Dir.glob('*.csv') do |filename|
  #Parse components of the filename to get information that will be prepended to each
  #row within this file when it's output to the aggregate file
  parts = File.basename(filename, File.extname(filename)).split('-')
  next unless parts.length >= 3
  ruby_ver = parts[0]
  platform = parts[1]
  test_variant = parts[2..-1].join('-')

  File.open(filename, 'r') do |file|
    file_header = file.readline.chomp.split(',')

    file.each_line do |line|
      line = line.chomp.split(',')

      # Create a hash where the keys are the column lables in file_header, and the values
      # are the correponsing columns in line
      line_data = {}
      file_header.size.times do |i|
        line_data[file_header[i]] = line[i]
      end

      #Determine which site this corresponds to
      site = line_data[SITE_NAME_COLUMN]

      #keep a unique list of sites
      sites << site unless sites.include?(site)

      #Compute the CPU percentage 
      cpu_percentage = line_data[TOTAL_CPU_TIME_COLUMN].to_f / line_data[CLOCK_TIME_COLUMN].to_f


      #Determine which HTTP impl this corresponds to
      #if it's not net/http, use the name of the impl
      #if it is net/http, use the name of the test variant
      if line_data[IMPL_NAME_COLUMN] == NET_HTTP_IMPL_NAME
        impl = test_variant
      else
        impl = line_data[IMPL_NAME_COLUMN]
      end

      # Build a string that combines the platform, ruby version, and impl name, which will key the
      # data hash
      key = "#{ruby_ver} #{platform} #{impl}"
      data[key] ||= {}

      #Within the data[key] hash, there's a key for each site
      #The value for the key is an array of cpu percentage values
      #for the net/http implementation there will only be one value, but
      #since the other implementations get run once for every test varient, these
      #other implementations will have multiple runs in one file, and thus multiple cpu percentage
      #values.  Save them all, and we'll average them before output
      data[key][site] ||= []
      data[key][site] << cpu_percentage
    end
  end
end


#Output the results
print "Impl Names/Sites"
sites.each do |site|
  print ","
  print site
end
print "\n"

data.each_pair do |impl, sites_data|
  print impl
  sites.each do |site|
    cpu_percentages = sites_data[site]
    print ","
    print avg(cpu_percentages)
  end
  print "\n"
end

