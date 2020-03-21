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

  attr_accessor :controller, :options
  
  # cost for activated ability
  serialize :cost, JSON
  serialize :effect, JSON
  serialize :duration, JSON
  serialize :condition, JSON
  
  # activated abilities. options can be used for targetting and such
  def activate(**options)
    # options are the same as  with 'Player#play_card'
    return false unless activation == 'activated'
    
    self.options = options
    
    if card.is_sorcery? || card.is_instant?
      pay && resolve
    else
      pay && play
    end
  end
  
  def can_pay?
    # 'cost' without 'self' gives weird results
    cost = self.cost
    cost, args = cost.first if cost.is_a?(Hash)
    
    case cost
    when 'tap'
      card.untapped
    when 'mana'
      color, amount = args.first
      mana_pool.can_pay?(args)
    when 'life'
      card.controller.life > args
    end
  end
  
  def pay
    # 'cost' without 'self' gives weird results
    cost = self.cost
    cost, args = cost.first if cost.is_a?(Hash)
    
    case cost
    when 'tap'
      card.tap_it
    when 'mana'
      color, amount = args.first
      card.controller.pay_mana(color, amount)
    when 'life'
      card.controller.life -= args
    end
  end
  
  def play
    method, args = effect.first
    
    case method
    when 'mana' # mana abilities do not use the stack
      resolve
    else
      game.stack.add self
    end
  end
  
  def resolve
    effect.each do |method, args|
      # method, args = e.first
      # byebug
      if Card::STATES.include?(method.to_sym)
        card.send("#{method}=", args)
      elsif self.respond_to?(method, true)
        send(method, args)
      else
        # for abilitities that affect card properties
        game.register self
      end
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
    return true if condition.blank?
    method, args = condition.first
    
    case method
    when 'compare'
      compare args
    end
  end
  
  def controller
    card.controller
  end
  
  def affects?(target)
    return false unless options.try("[]", :target)
    affecting = options[:target]
    
    return true if affecting == target
    
    if affecting.is_a?(Array)
      return true if affecting.include?(target)
    end
    
    false
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
    card.power = amount
    
    targets = card.options[:target]
    targets = [targets] unless targets.is_a?(Array)
    
    targets.each do |target|
      card.assign_damage(target)
    end
  end
  
  def life(args)
    symbol, value = args.match(/([^0-9]*)([0-9]+)/)[1..2]
    symbol = "=" if symbol.empty?
    controller.life = controller.life.send(symbol, value.to_i)
  end
  
  def draw(args)
    controller.draw args
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
  
  def discard(args)
    case args['player']
    when 'target'
      card.options[:target].discard(args['amount'])
    end
    
  end
end
