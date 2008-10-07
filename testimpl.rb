#!/usr/bin/ruby -w
#
# Tests an HTTP impl to make sure it works
#
# Usage:
#  testimpl.rb [implname]
#
# if [implname] is eliminated, all available impls will be tested
require 'net/http'
require 'digest/md5'
require 'http_impls'

TEST_URL = "http://manage2.futurehosting.biz/test.zip"


# The reference HTTP implementation, which is used to get the reference file to compare
# other impls with
def reference_get(uri)
    hash = start_hash
    bytes = 0

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request_get(uri.path) do |response|
        response.read_body do |body|
          add_hash(hash, body)
          bytes += body.length
        end
      end
    end

    [bytes, complete_hash(hash)]
end

def test_get(impl, uri)
    hash = start_hash
    bytes = 0

    impl.test_get_impl(uri) do |body|
      add_hash(hash, body)
      bytes += body.length
    end

    [bytes, complete_hash(hash)]
end

class HashMismatchError < Exception
    def initialize(expected_hash, actual_hash, actual_bytes)
        super("#{actual_bytes} bytes returned with mismatched hash.  Expected #{expected_hash}; got #{actual_hash}")
    end
end

def start_hash
    Digest::MD5.new
end

def add_hash(hash, data)
    hash.update(data)
end

def complete_hash(hash)
    hash.hexdigest
end

test_impl_name = nil
test_impl_name = ARGV[0] unless ARGV.length < 1

impls_to_test = []

HttpImpls.get_impls.each do |impl|
    impls_to_test << impl unless (test_impl_name != nil and test_impl_name == impl.name) or !impl.available
end

if impls_to_test.length == 0
    puts "No tests selected.  To run all tests, invoke with no arguments.  To run a specific test, use one of the following:"
    HttpImpls.get_impls.each do |impl|
        puts "  #{impl.name}"
    end
    exit
end

test_uri = URI.parse(TEST_URL)

puts "Downloading data with reference impl from #{test_uri}"

reference_bytes, reference_hash = reference_get(test_uri)

puts "Reference implementation returned data with #{reference_bytes} bytes, hash #{reference_hash}"

impls_to_test.each do |impl|
    print "Downloading data with impl #{impl.name}..."

    begin
        test_bytes, test_hash = test_get(impl, test_uri)

        if reference_hash != test_hash
            raise HashMismatchError.new(reference_hash, test_hash, test_bytes)
        end
    rescue HashMismatchError
        # On hash mismatch, just show the message
        print "#{$!}\n"
    rescue
        # On other errors, show a stack trace too
        print "ERROR: #{$!}\n"
        $!.backtrace.each do |frame|
            print "  #{frame}\n"
        end
        next
    end

    print "OK\n"
end

puts "Test(s) complete"

