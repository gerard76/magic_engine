class Ability < ApplicationRecord
  belongs_to :card
  
  attr_accessor :modal
  attr_accessor :type # Activated, Triggered, and Static
  attr_accessor :trigger
  serialize :costs, JSON
  serialize :effects, JSON
  
  def pay_cost
    costs.each_pair do |cost, args|
      case cost
      when :tap
        card.tap_it
      when :mana
        card.owner.pay_mana(args[:color], args[:amount])
      end
    end
  end
  
  def execute
    effects.each_pair do |effect, args|
      case effect
      when :mana
        card.owner.mana_pool.add(args[:color], args[:amount])
      end
    end
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