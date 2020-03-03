class Card < ApplicationRecord
  attr_accessor :owner, :zone, :game
  # attr_accessor :controller ?
  attr_accessor :face_down, :tapped
  
  attr_accessor :damage, :deathtouch_damage
  
  has_many :triggers
  has_many :abilities
  
  def add_default_abilities
    types.each do |type|
      case type
      when 'Land'
        if supertypes.include?('Basic')
          Ability.new(cost: :tap, effects: { mana: { color: color, amount: 1 }})
        end
      end
    end
  end
  
  def add_effect(trigger, effect, args)
    effects << Effect.new(trigger, effect, args)
  end
  
  def activate_ability(ability)
    owner.pay(ability.costs)
    
    ability.execute
  end
  
  def tap
    @tapped = true
  end
  
  def untap
    @tapped = false
  end
  
  def move(to_zone)
    @zone.delete self
    to_zone.add self
  end
 
  def color
    color_identity.map { |c| c.downcase.to_sym }
  end
  
  def to_s
    cost = " - #{mana_cost}"
    puts "#{id}: #{name} - #{card_type} #{cost}"
  end
  
  def playable?
    # can I play?
    zone.name == :hand &&
    # can I pay?
    payable?
  end
  
  def playable_zones
    [:hand] # + any zone added by ability
  end
  
  def max_in_deck
    return 1000 if types.include?('Land') && supertypes.include?('Basic')
    
    abilities.each do |ability|
      ability.effects.each_pair do |effect, args|
        return args['amount'] if effect == 'max_in_deck'
      end
    end 
    return 4
  end
end

# A:SP$ ChangeZone | Cost$ 1 B | Origin$ Graveyard | Destination$ Hand | TargetMin$ 0 | TargetMax$ 2 | TgtPrompt$ Choose target creature card in your graveyard | ValidTgts$ Creature.YouOwn | SpellDescription$ Return up to two target creature cards from your graveyard to your hand, then discard a card. | SubAbility$ DBDiscard
# SVar:DBDiscard:DB$Discard | Defined$ You | NumCards$ 1 | Mode$ TgtChoose
# DeckHints:Ability$Graveyard & Ability$Discard
# DeckHas:Ability$Discard

