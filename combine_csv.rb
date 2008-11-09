#!/usr/bin/ruby -w

require 'fastercsv'

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

def load_data
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
        lines = FasterCSV.read(filename)

        file_header = lines[0]
        lines = lines[1..-1]

        lines.each do |line|
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


            impl = line_data[IMPL_NAME_COLUMN]


            # Build a string that combines the platform, ruby version, and impl name, which will key the
            # data hash
            #key = "#{ruby_ver} #{platform} #{impl}"
            key = impl
            data[key] ||= {}

            #Within the data[key] hash, there's a key for each site
            #The value for the key is an array of cpu percentage values
            #for the net/http implementation there will only be one value, but
            #since the other implementations get run once for every test varient, these
            #other implementations will have multiple runs in one file, and thus multiple cpu percentage
            #values.  Save them all, and we'll average them before output
            data[key][site] ||= {}
            data[key][site][:cpu_percentage] ||= []
            data[key][site][:cpu_percentage] << cpu_percentage
            data[key][site][:total_cpu_time] ||= []
            data[key][site][:total_cpu_time] << line_data[TOTAL_CPU_TIME_COLUMN].to_f
            data[key][site][:clock_time] ||= []
            data[key][site][:clock_time] << line_data[CLOCK_TIME_COLUMN].to_f
        end
    end

    [sites, data]
end

def output_results(sites, data, metric)
  filename = "#{metric.to_s}.txt"
  puts "Generating #{filename}"
  File.open(filename, "w") do |file|
    
    #Output the results
    file << "Impl Names/Sites,"
    file << sites.join(',') << "\n"
    
    data.each_pair do |impl, sites_data|
      file << impl
      sites.each do |site|
        stat = sites_data[site][metric]
        file << ","
        file << avg(stat)
      end
      file << "\n"
    end
  end

end

sites, data = load_data
output_results(sites, data, :cpu_percentage)
output_results(sites, data, :total_cpu_time)
output_results(sites, data, :clock_time)

