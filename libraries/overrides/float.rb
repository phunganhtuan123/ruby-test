Float.class_eval do
  # 0.1 => 0.5, 0.5 => 0.5, 0.6 => 1, 1 => 1, 1.1 => 1.5
  def round_to_half
    whole, remainder = divmod(0.5)
    num_steps = remainder > 0 ? whole + 1 : whole
    num_steps * 0.5
  end
end
