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
  serialize :cost, JSON
  serialize :effect, JSON
  serialize :duration, JSON
  serialize :condition, JSON
  
  # activated abilities
  
  def activate
    
    return false unless activation == 'activated'
    pay && play
  end
  
  def pay
    # 'cost' without 'self' gives weird results
    if self.cost.is_a?(Hash)
      cost, args = cost.first
    end
    
    case self.cost
    when 'tap'
      card.tap_it
    when 'mana'
      color, amount = args.first
      card.controller.pay_mana(color, amount)
    end
  end
  
  def play
    method, args = effect.first
    case method
    when 'mana' # mana abilities do not use the stack
      resolve
    else
      game.stack.add(method, args)
    end
  end
  
  def resolve
    method, args = effect.first
    if Card::STATES.include?(method.to_sym)
      card.send("#{method}=", args)
    else
      send(method, args)
    end
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
    return true if condition.empty?
    method, args = condition.first
    
    case method
    when 'compare'
      compare args
    end
  end
  
  def controller
    card.controller
  end
  
  private
  
  ### EFFECTS:
  def mana(args)
    color, operation = args.first
    symbol, value = operation.match(/([^0-9]*)([0-9]+)/)[1..2]
    if symbol == "+"
      card.controller.mana_pool.add(color, value.to_i)
    end
  end
  
  def damage(amount)
    get_targets.each do |target|
      card.power = amount
      card.assign_damage(target)
    end
  end
  
  def life(args)
    symbol, value = args.match(/([^0-9]*)([0-9]+)/)[1..2]
    symbol = "=" if symbol.empty?
    controller.life = controller.life.send(symbol, value.to_i)
  end
  
  def power(args)
    symbol, value = args.match(/([^0-9]*)([0-9]+)/)[1..2]
    symbol = "=" if symbol.empty?
    card.power.send(symbol, value.to_i)
  end
  
  def toughness(args)
    symbol, value = args.match(/([^0-9]*)([0-9]+)/)[1..2]
    symbol = "=" if symbol.empty?
    card.toughness.send(symbol, value.to_i)
  end
  
  ### CONDITIONS:
  
  def call_method(method)
  end
  
  def compare(args)
    # returns true or false
    this = args['this']
    that = args['that']
    
    method, args = this.first
    
    this = case method
    when 'count'
      count args
    end
  
    operation, value = that.match(/([^0-9]*)([0-9]+)/)[1..2]
    
    this.send(operation, value.to_i)
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
