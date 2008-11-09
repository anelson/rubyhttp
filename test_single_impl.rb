#!/usr/bin/ruby -w

require 'benchmark'
require 'http_impls'
require 'uri'

MIN_COLUMN_WIDTH = 25
MAX_SITE_NAME_LENGTH = 15

#REMOTE_URL = "http://seattle.futurehosting.biz/test100.zip"
#REMOTE_URL = "http://seattle.futurehosting.biz/test.zip"
#REMOTE_URL = "http://wdc01.futurehosting.biz/test100.zip"
#REMOTE_URL = "http://wdc01.futurehosting.biz/test.zip"

REMOTE_URLS = {
  "seattle" => "http://seattle.futurehosting.biz/test.zip",
  "washdc" => "http://wdc01.futurehosting.biz/test.zip",
  "dallas" => "http://manage2.futurehosting.biz/test.zip",
  "chicago" => "http://chicagospeedtest.futurehosting.biz/test.zip",
  "london" => "http://uk.futurehosting.biz/test.zip",
}

def run_test
  results = []
  #After running all the tests group the results by implementation
  impl_name_column_width = MIN_COLUMN_WIDTH

  #Pad the impl_name with space for the site name before the runtime numbers
  impl_name_column_width += MAX_SITE_NAME_LENGTH

  Benchmark.benchmark(" "*impl_name_column_width + Benchmark::CAPTION, 
    impl_name_column_width, 
    Benchmark::FMTSTR 
    ) do |x|
    HttpImpls::get_impls.each do |impl|
      next unless impl.available
      times = []
  
      REMOTE_URLS.each_pair do |site_name, remote_url|
        test = OpenStruct.new({ :site_name => "#{site_name}", :site_url => remote_url, :impl => impl, :name => "#{site_name} with #{impl.description}"})
        
        stats = test_impl(x, test)
        results << stats
  
        times << stats.tm
      end
    end
  end

  results
end
  
def test_impl(bm, test)
  uri = URI.parse(test.site_url)

  stats = nil
  tm = bm.report(test.name) do 
    stats = test.impl.get(uri)
  end

  stats.tm = tm
  stats.test = test

  stats
end

def print_results(results)
  results.each do |stats|
    puts "#{stats.test.name}:"
    puts "\t#{stats.bytes/1024} Kbytes transferred in #{stats.chunk_count} chunks"
    puts "\t#{(stats.bytes / 1024) / stats.tm.real} Kbytes/second"
    puts "\tMean chunk size #{stats.mean_chunk_size} bytes"
    puts "\tMax chunk size #{stats.max_chunk_size} bytes"
    puts "\tMin chunk size #{stats.min_chunk_size} bytes"
    puts
  end
end

def write_results_to_csv(results, result_file) 
  File.open(result_file, 'w') do |file|
    #Output the test results as a CSV file
    file << "Site,Impl,Test,KBytes Transferred,KBytes/second,Chunk Count,Mean Chunk Size,Max Chunk Size,Min Chunk Size,User Time,System Time,Total CPU Time,Clock Time\n"
    
    results.each do |stats|
      file << "\"#{stats.test.site_name}\","
      file << "\"#{RUBY_VERSION} #{RUBY_PLATFORM} #{stats.test.impl.name}\","
      file << "\"#{stats.test.name}\","
      file << "#{stats.bytes/1024},"
      file << "#{(stats.bytes / 1024) / stats.tm.real},"
      file << "#{stats.chunk_count},"
      file << "#{stats.mean_chunk_size},"
      file << "#{stats.max_chunk_size},"
      file << "#{stats.min_chunk_size},"
      file << "#{stats.tm.utime},"
      file << "#{stats.tm.stime},"
      file << "#{stats.tm.total},"
      file << "#{stats.tm.real}"
      file << "\n"
    end
  end
  
  puts "Test results written in CSV format to #{result_file}"
end

def main(argv)
  if ARGV.length != 1
    puts "Usage: test_single_impl.rb <impl_name>"
    exit(-1)
  end
  
  impl_name = ARGV[0]
  HttpImpls.load_single_impl(impl_name)
  raise RuntimeError, "Invalid implementation name" unless (HttpImpls.get_impls.length) > 0 

  result_dir = File.dirname(__FILE__) + "/results/#{Time.new().strftime('%Y-%m-%d')}"
  result_file = result_dir + "/ruby-#{RUBY_VERSION}-#{RUBY_PLATFORM}-#{impl_name}.csv"

  results = run_test
  
  print_results(results)
  
  Dir.mkdir(result_dir) rescue nil
  write_results_to_csv(results, result_file)
end

main(ARGV)
