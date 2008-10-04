require 'ostruct'

### Base class for HTTP implementations
class HttpImpl
  attr_reader :name
  attr_reader :available

  def initialize(name, available)
    @name = name
    @available = available

    register()
  end

  ### Sends an HTTP GET to the specified URL
  def get(uri)
    #Subclasses must implement the method get_impl, which yields each chunk of the body
    stats = OpenStruct.new({:bytes => 0, :chunk_count => 0, :min_chunk_size => 0, :max_chunk_size => 0, :mean_chunk_size => 0})

    get_impl(uri) do |chunk|
      stats.bytes += chunk.length
      stats.chunk_count += 1
      stats.min_chunk_size = chunk.length if stats.min_chunk_size == 0 || stats.min_chunk_size > chunk.length
      stats.max_chunk_size = chunk.length if stats.max_chunk_size == 0 || stats.max_chunk_size < chunk.length
    end   
    
    stats.mean_chunk_size = (stats.bytes / stats.chunk_count)

    stats
  end

  private

  def register
    HttpImpls::register_impl(self)
  end

end

