class Ability < ApplicationRecord
  belongs_to :card
  
  # Abilities always fall into one of four categories: spell abilities, activated abilities, triggered abilities, and static abilities.
  # A triggered ability is an ability that automatically does something when a certain event occurs or a set of conditions is met (the latter is called a state-triggered ability).
  
  # event <- when it should trigger
  # expire <- when it should expire
  # effect <- what it should do
  # 
  %w(activated static triggered).each do |a|
    define_method(a) do
      activation == a
    end
  end

  attr_accessor :controller
  
  # cost for activated ability
  serialize :costs, JSON
  serialize :effect, JSON
  serialize :duration, JSON
  
  # activated abilities
  
  def activate
    return false unless activation == 'activated'
    pay && play
  end
  
  def pay
    case cost
    when 'tap'
      card.tap_it
    when 'mana'
      card.controller.pay_mana(args['color'], args['amount'])
    end
  end
  
  def play
    case name('effect')
    when 'mana' # mana abilities do not use the stack
      resolve
    else
      game.stack.add(effect, args('effect'))
    end
  end
  
  def resolve
    case name('effect')
    when 'tapped'
      set_state('tapped')
    else
      self.send name('effect')
    end
  end
  
  def args(key)
    send(key).first[1..-1]
  end
  
  def name(key)
    value = send(key)
    return value.first.first if value.is_a?(Hash)
    value
  end
  
  LAYER = {
    power: 8,
    toughness: 8,
    state: 6,
    trigger: 6,
    abililty: 6,
    color: 5,
    type: 4
  }
  
  def layer
    LAYER[name] || 0
  end
  
  # used to check if a static ability is currently active
  def active?
    return true if trigger.empty?
    
    case name('trigger')
    when 'compare'
      compare *trigger.values.first
    end
  end
  
  def controller
    card.controller
  end
  
  private
  
  ### EFFECTS:
  def mana
    color = args('effect').first
    color, amount = color.first if color.first.is_a? Array
    card.controller.mana_pool.add(color, amount)
  end
  
  def damage
    get_targets.each do |target|
      card.power = args('effect').first
      card.assign_damage(target)
    end
  end
  
  def gain_life(amount = 1)
    controller.assign_life amount
  end
  
  def set_state(states)
    states = [states] unless states.is_a? Array
    states.each do |state|
      card.send("#{state}=", true)
    end
  end
  
  def power
    symbol, value = args.match(/([^0-9]*)([0-9]+)/)[1..2]
    symbol = "=" if symbol.empty?
    card.send("power#{symbol}", value)
  end
  
  def toughness
    symbol, value = args.match(/([^0-9]*)([0-9]+)/)[1..2]
    symbol = "=" if symbol.empty?
    card.send("toughness#{symbol}", value)
  end
  
  ### CONDITIONS:
  
  def compare(this, that)
    # returns true of false
    
    arg1 = case this.keys.first
    when 'count'
      count this.values.first
    end
    
    operation, value = that.match(/([^0-9]*)([0-9]+)/)[1..2]
    
    arg1.send(operation, value.to_i)

  end
  
  def count(card_filter_array)
    cards = game.cards
    
    card_filter_array.each do |filter|
      if filter == "control"
        cards = cards.select { |card| card.controller == controller }
      else
        cards = cards.select { |card| card.send("#{filter}?") }
      end
    end
    cards.size
  end
  
  def get_targets
    targets = card.args
    targets = [targets] unless targets.is_a?(Array)
    targets
  end
  
  def get_possible_targets(args)
    battlefield = game.battlefield
    case args['type']
    when 'any'
      battlefield.creatures + game.players + battlefield.planeswalkers
    when 'player'
      players
    when 'creature'
      battlefield.creatures
    when 'permanent'
      battlefield.cards
    end
  end
  
  def game
    card.controller.game
  end

end
