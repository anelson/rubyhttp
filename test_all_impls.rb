#!/usr/bin/ruby -w

require 'http_impls'

def main
  ruby_command = "ruby -rubygems -w "
  if (ARGV.length == 1)
   ruby_command = ARGV[0]
  elsif (ARGV.length > 1)
    puts "Usage: test_all_impls.rb [ruby command]"
    exit( -1)
  end

  HttpImpls.load_all_impls

  HttpImpls.get_impls.each do |impl|
    print "#{impl.name} "
    if impl.available 
      puts "(available)"
    else 
      puts "(not available)"
    end

    if impl.available
      run_test(ruby_command, impl)
    end
  end
end

def run_test(ruby_command, impl)
  puts "Running test for HTTP implementation #{impl.name}"
  retval = system("#{ruby_command} " + File.dirname(__FILE__) + "/test_single_impl.rb #{impl.name}")
 
  if (!retval || $? != 0)
    raise RuntimeError, "Test failed.  system returned #{retval}; exit code #{$?}"
  else
    puts "Test ran successfully"
  end
end
 

main

