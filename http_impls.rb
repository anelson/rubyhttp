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
end

Dir.glob(File.dirname(__FILE__) + "/impls/*.rb").each do |file|
  begin
    require file
  rescue LoadError
    warn("Unable to load HTTP impl '#{file}': #{$!}")
  end
end

