#!/usr/bin/ruby -w

require 'net/http'
require 'benchmark'

if ARGV.length != 1
  puts "Usage: rubyhttp.rb <results file name>"
  exit(-1)
end

result_file = ARGV[0]

puts "Writing results to file #{result_file}"

begin
  require 'curb'
  curb_available = true
  puts "curb tests are available"
rescue LoadError
  curb_available = false
  puts "curb tests are not available (#{$!})"
end

COLUMN_WIDTH = 25

#REMOTE_URL = "http://seattle.futurehosting.biz/test100.zip"
#REMOTE_URL = "http://seattle.futurehosting.biz/test.zip"
#REMOTE_URL = "http://wdc01.futurehosting.biz/test100.zip"
#REMOTE_URL = "http://wdc01.futurehosting.biz/test.zip"

REMOTE_URLS = {
  #"seattle" => "http://seattle.futurehosting.biz/test.zip",
  "washdc" => "http://wdc01.futurehosting.biz/test.zip",
  "dallas" => "http://manage2.futurehosting.biz/test.zip",
  #"chicago" => "http://chicagospeedtest.futurehosting.biz/test.zip",
  #"london" => "http://uk.futurehosting.biz/test.zip",
}

IMPLEMENTATIONS = {
  "net/http" => {
    :available => true, # net/http is ALWAYS available
    :proc => 
      proc { |bm, test, remote_url|
        stats = Hash.new(0)
    
        url = URI.parse(remote_url)
    
        tm = bm.report(test[:name]) do
          Net::HTTP.start(url.host, url.port) do |http|
            http.request_get(url.path) do |response|
              response.read_body do |body|
                stats[:bytes] += body.length
                stats[:chunk_count] += 1
                stats[:min_chunk_size] = body.length if stats[:min_chunk_size] == 0 || stats[:min_chunk_size] > body.length
                stats[:max_chunk_size] = body.length if stats[:max_chunk_size] == 0 || stats[:max_chunk_size] < body.length
              end
            end
          end
        end
    
        stats[:tm] = tm
        stats[:test] = test
    
        stats
    }
  },

  "libcurl" => {
    :available => curb_available,
    :proc => proc { |bm, test, remote_url|
        return nil unless curb_available
        stats = Hash.new(0)
    
        tm = bm.report(test[:name]) do
          c = Curl::Easy.new(remote_url)
          c.on_body do |body|
            stats[:bytes] += body.length
            stats[:chunk_count] += 1
            stats[:min_chunk_size] = body.length if stats[:min_chunk_size] == 0 || stats[:min_chunk_size] > body.length
            stats[:max_chunk_size] = body.length if stats[:max_chunk_size] == 0 || stats[:max_chunk_size] < body.length
    
            body.length
          end
    
          c.perform
        end
    
        stats[:tm] = tm
        stats[:test] = test
    
        stats
    }
  }
}

results = []
#After running all the tests group the results by implementation
impl_times = {}
impl_names = []
impl_total_labels = []

IMPLEMENTATIONS.each_pair do |key, value|
  break unless value[:available]

  impl_names << key
  impl_total_labels << ">all #{key}"
end

#puts "Impl names:"
#impl_names.each {|name|  puts name}

#Benchmark.benchmark(" "*20 + Benchmark::CAPTION, 20, Benchmark::FMTSTR, *impl_names) do |x|
Benchmark.benchmark(" "*COLUMN_WIDTH + Benchmark::CAPTION, 
  COLUMN_WIDTH, 
  Benchmark::FMTSTR, 
  *impl_total_labels) do |x|
  IMPLEMENTATIONS.each_pair do |impl_name, details|
    break unless details[:available]
    times = []

    REMOTE_URLS.each_pair do |site_name, remote_url|
      test = { :site => "#{site_name}", :impl => "#{impl_name}", :name => "#{site_name} with #{impl_name}"}

      stats = details[:proc].call(x, test, remote_url)
      results << stats

      times << stats[:tm]
    end
    impl_times[impl_name] = times

    #puts "impl_times[#{impl_name}] = #{times}"
  end

  impl_totals = []
  impl_names.each do |impl_name|
    tm = Benchmark::Tms.new()
    impl_times[impl_name].each do |impl_time|
      tm = tm + impl_time
    end
    impl_totals << tm
  end

  #puts "Impl totals: "
  #impl_totals.each {|tm| puts tm.format(Benchmark::FMTSTR)}

  impl_totals
end

results.each do |stats|
  puts "#{stats[:test][:name]}:"
  puts "\t#{stats[:bytes]/1024} Kbytes transferred in #{stats[:chunk_count]} chunks"
  puts "\t#{(stats[:bytes] / 1024) / stats[:tm].real} Kbytes/second"
  puts "\tMean chunk size #{stats[:bytes] / stats[:chunk_count]} bytes"
  puts "\tMax chunk size #{stats[:max_chunk_size]} bytes"
  puts "\tMin chunk size #{stats[:min_chunk_size]} bytes"
  puts
end

File.open(result_file, 'w') do |file|
  #Output the test results as a CSV file
  file << "Site,Impl,Test,KBytes Transferred,KBytes/second,Chunk Count,Mean Chunk Size,Max Chunk Size,Min Chunk Size,User Time,System Time,Total CPU Time,Clock Time\n"
  
  results.each do |stats|
    file << "#{stats[:test][:site_name]},"
    file << "#{stats[:test][:impl_name]},"
    file << "#{stats[:test][:name]},"
    file << "#{stats[:bytes]/1024},"
    file << "#{(stats[:bytes] / 1024) / stats[:tm].real},"
    file << "#{stats[:chunk_count]},"
    file << "#{stats[:bytes] / stats[:chunk_count]},"
    file << "#{stats[:max_chunk_size]},"
    file << "#{stats[:min_chunk_size]},"
    file << "#{stats[:tm].utime},"
    file << "#{stats[:tm].stime},"
    file << "#{stats[:tm].total},"
    file << "#{stats[:tm].real}"
    file << "\n"
  end
end

puts "Test results written in CSV format to #{result_file}"


  
  

