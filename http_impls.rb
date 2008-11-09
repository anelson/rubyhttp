# Discover available implementations
module HttpImpls
  private

  @impls = []

  public

  def HttpImpls.register_impl(impl)
    @impls << impl
  end

  def HttpImpls.get_impls
    @impls
  end

  def HttpImpls.load_all_impls
	Dir.glob(File.dirname(__FILE__) + "/impls/*.rb").each do |file|
	  begin
	    require file
	  rescue LoadError
	    warn("Unable to load HTTP impl '#{file}': #{$!}")
	  end
	end
  end
 
  def HttpImpls.load_single_impl(impl_name)
    begin
      require File.dirname(__FILE__)+"/impls/"+impl_name + ".rb"
    rescue LoadError
      warn("Unable to load HTTP impl '#{impl_name}': #{$!}")
    end
  end
end


