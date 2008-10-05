#!/usr/bin/ruby -w

require 'benchmark'
require 'http_impls'

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

def run_tests
  results = []
  #After running all the tests group the results by implementation
  impl_times = {}
  impl_names = []
  impl_total_labels = []
  
  impl_name_column_width = MIN_COLUMN_WIDTH

  HttpImpls::get_impls.each do |impl|
    next unless impl.available
  
    impl_names << impl.name
    impl_total_labels << ">all #{impl.name}"

    impl_name_column_width = impl.name.length unless impl_name_column_width > impl.name.length
  end
  
  puts "Impl names:"
  impl_names.each {|name|  puts name}
  
  #Pad the impl name with space for the site name before the runtime numbers
  impl_name_column_width += MAX_SITE_NAME_LENGTH
  #Benchmark.benchmark(" "*20 + Benchmark::CAPTION, 20, Benchmark::FMTSTR, *impl_names) do |x|
  Benchmark.benchmark(" "*impl_name_column_width + Benchmark::CAPTION, 
    impl_name_column_width, 
    Benchmark::FMTSTR, 
    *impl_total_labels) do |x|
    HttpImpls::get_impls.each do |impl|
      next unless impl.available
      times = []
  
      REMOTE_URLS.each_pair do |site_name, remote_url|
        test = OpenStruct.new({ :site_name => "#{site_name}", :site_url => remote_url, :impl => impl, :name => "#{site_name} with #{impl.name}"})
        
        stats = run_test(x, test)
        results << stats
  
        times << stats.tm
      end
      impl_times[impl.name] = times
  
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

  results
end
  
def run_test(bm, test)
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
      file << "#{stats.test.site_name},"
      file << "#{stats.test.impl.name},"
      file << "#{stats.test.name},"
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
  if ARGV.length > 1
    puts "Usage: rubyhttp.rb [results file name]"
    exit(-1)
  end
  
  result_file = nil
  result_file = ARGV[0] unless ARGV.length < 1

  results = run_tests
  
  print_results(results)
  
  if result_file != nil
    write_results_to_csv(results, result_file)
  end
end

main(ARGV)
