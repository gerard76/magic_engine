class String
  def numeric?
    # `!!` converts parsed number to `true`
    !!Kernel.Float(self) 
  rescue TypeError, ArgumentError
    false
  end
end