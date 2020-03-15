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
  
  # 603.3c If a triggered ability is modal, its controller announces the mode choice when putting the ability on the stack. If one of the modes would be illegal (due to an inability to choose legal targets, for example), that mode can’t be chosen. If no mode is chosen, the ability is removed from the stack. (See rule 700.2.)
  attr_accessor :modal
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
    case name
    when 'mana' # mana abilities do not use the stack
      resolve
    else
      game.stack.add(effect, args)
    end
  end
  
  def resolve
    case name
    when 'tapped'
      set_state('tapped')
    else
      self.send name
    end
  end
  
  def args
    effect.first[1..-1]
  end
  
  def name
    return effect.first.first if effect.is_a?(Hash)
    effect
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
  
  private
  
  def mana
    color = args.first
    color, amount = color.first if color.first.is_a? Array
    card.controller.mana_pool.add(color, amount)
  end
  
  def damage
    get_targets.each do |target|
      card.power = args.first
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

# https://mtg.fandom.com/wiki/Abilities
# There are three main Abilities of abilities: Activated, Triggered, and Static.
# activated ability:
# Conditions. Cost: Effect 
# Like instants, these abilities can be played at nearly any time during the game (see timing and the stack). Activated Abilities can be played as many times as you can pay for the cost. Activated Abilities, like instants, go on the stack.

# Triggered Abilities are abilities that activate when certain conditions are met.
# Condition: Effect
# Whenever the triggered event occurs, the ability is put on the stack the next time a player would receive priority and stays there until it's countered, it resolves, or otherwise leaves the stack.

# 603.3c If a triggered ability is modal, its controller announces the mode choice when putting the ability on the stack. If one of the modes would be illegal (due to an inability to choose legal targets, for example), that mode can’t be chosen. If no mode is chosen, the ability is removed from the stack. (See rule 700.2.)