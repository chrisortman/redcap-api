module RedCAP::API::HashRecordAccessors

  def record_id
    self[:record_id]
  end

  def record_id=(val)
    self[:record_id] = val
  end

  def instrument=(val)
    self[:redcap_repeat_instrument] = val
  end

  def instrument
    self[:redcap_repeat_instrument]
  end

  def instance=(val)
    self[:redcap_repeat_instance] = val
  end

  def instance
    self[:redcap_repeat_instance]
  end

  def redcap_hash
    self
  end

end
