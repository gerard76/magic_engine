class ManaPool
  # Colorless, Black, Green, Blue, Red, White
  # TODO snow!
  COLORS = {
    generic:   'x', 
    colorless: 'c',
    plains:    'w',
    swamp:     'b',
    forest:    'g',
    island:    'u',
    mountain:  'r'
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
  
  def pay_mana(mana_string, x = 0)
    return true if mana_string.blank?
    return false unless can_pay?(mana_string)
    
    mana_hash = convert_mana_string(mana_string)
    
    mana_hash.each do |color, amount| 
      if color == 'x'
        generic = amount
        @pool.each do |color, amount|
          amount = [generic, amount].min
          pay(color, amount)
          generic -= amount
          
          break unless generic > 0
        end
      else
        pay(color, amount)
      end
    end
    
    true
  end
  
  def can_pay?(mana, x = 0)
    return true if mana.blank?
    mana_hash    = convert_mana_string(mana) if mana.is_a?(String)
    
    mana_hash.each do |color, amount|
      if color == 'x'
        return false if amount > total_mana # check generic mana against total mana
      else
        return false if color.split('/').all? { |c| @pool[c] < amount } # split for multicolor
      end
    end
    
    return false if mana_hash.values.sum > total_mana
    
    true
  end
  
  def to_pay_color(mana_hash)
    pay = {}
    mana_hash.each do |color, amount|
      next if color.to_s.numeric?
      
      pay[color] = amount
    end
    pay
  end
  
  def to_pay_generic(mana_hash, x)
    generic = 0
    mana_hash.each do |color, amount|
      (generic += color.to_i) && next if color.to_s.numeric?
      (generic += x && next) if color == 'x'
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
  
  def self.convert_mana_string(mana_string)
    # mana string examples:
    # {3}{B}{G}{U}
    # {X}{B}{G}{U}
    # {B/G}{R}
    array = mana_string[1..-2].split('}{').map(&:downcase).tally
    #  {"3"=>1, "b"=>2, "g"=>1}
    # put generic count in value instead of key
    res = {}
    array.each_pair do |key, value|
      key.numeric? ? res['x']=key.to_i  : res[key]=value
    end
    res
  end
  
  def convert_mana_string(mana_string)
    ManaPool.convert_mana_string(mana_string)
  end
  
  def valid_color?(color)
    return false unless COLORS.values.include?(color)
    true
  end
end
