class ManaPool
  # Colorless, Black, Green, Blue, Red, White
  # TODO snow!
  COLORS = {
    colorless: 'C',
    plains:    'W',
    swamp:     'B',
    forest:    'G',
    island:    'U',
    mountain:  'R'
  }
  
  delegate *(Hash.new.methods - Object.methods), to: :@pool
  
  def initialize
    @pool = Hash[COLORS.values.map { |color| [color, 0] }]
  end
  
  def add(color, amount = 1)
    amount ||= 1
    color = color.to_s
    @pool[color] += amount if valid_color?(color)
    
  end
  
  def pay(color, amount = 1)
    color = color.to_s
    @pool[color] -= amount if valid_color?(color)
  end
  
  def empty
    initialize
  end
  
  # TODO I do not like this mana string. maybe convert before calling mana pool?
  def pay_mana(mana_string, x = 0)
    return true if mana_string.blank?
    return false unless can_pay?(mana_string)
    
    mana_array = convert_mana_string(mana_string)
    
    # pay color
    to_pay_color(mana_array).each { |color, amount| pay(color, amount) }
    
    # pay generic
    generic = to_pay_generic(mana_array, x)
    
    if generic > 0
      # colorless is first in pool, so that is spend first
      @pool.each_pair do |color, amount|
        amount = [generic, amount].min
        pay(color, amount)
        generic -= amount
      
        break unless generic > 0
      end
    end
    true
  end
  
  def can_pay?(mana_string, x = 0)
    return true if mana_string.blank?
    mana_array   = convert_mana_string(mana_string)
    generic_mana = to_pay_generic(mana_array, x)
    color_mana   = to_pay_color(mana_array)
    
    color_mana.each do |color, amount|
      return false if @pool[color] < amount
    end
    return false if (generic_mana + color_mana.values.sum) > total_mana
    
    true
  end
  
  def to_pay_color(mana_array)
    pay = {}
    mana_array.each do |color, amount|
      next if color.to_s.numeric?
      next if color == 'X'
      
      pay[color] = amount
    end
    pay
  end
  
  def to_pay_generic(mana_array, x)
    generic = 0
    mana_array.each do |color, amount|
      (generic += color.to_i) && next if color.to_s.numeric?
      (generic += x && next) if color == 'X'
    end
    generic
  end
  
  def to_s
    @pool.each_pair do |color, amount|
      puts "#{color}: #{amount}"
    end
  end
  
  def total_mana
    @pool.values.sum
  end
  
  private
  
  def convert_mana_string(mana_string)
    # mana string examples:
    # {3}{B}{G}{U}
    # {X}{B}{G}{U}
    # {B/G}{R}
    array = mana_string[1..-2].split('}{')
    array.map { |a| a.numeric? ? a : a }.tally
  end
  
  def valid_color?(color)
    return false unless COLORS.values.include?(color)
    true
  end
end
