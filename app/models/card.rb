class Card < ApplicationRecord
  
  STATES = %i(
    face_down
    tapped
    sick
    attacking
    attacked
    blocking
    blocked
    unblocked
  )
  
  attr_accessor :owner, :zone
  attr_reader :controller
  
  # states
  attr_accessor *STATES
  after_initialize :set_default_state_values
  
  attr_accessor :damage, :deathtouch_damage
  
  has_many :triggers
  has_many :abilities
  
  def activate_ability(ability)
    owner.pay(ability.costs)
    
    ability.execute
  end
  
  def tap_it
    return false if tapped || sick
    
    abilities.where("cost ->> 'tap' = 'self'" ).each(&:execute)
    self.tapped = true
  end
  
  def untap
    return false unless tapped
    self.tapped = false
    true # lets return succes
  end
  
  def controller=(player)
    # A permanent is removed from combat if its controller changes
    remove_from_combat if player != controller
    @controller = player
  end
  
  def move(to_zone)
    # 506.4. A permanent is removed from combat if it leaves the battlefield
    remove_from_combat if zone.name == :battlefield
    
    zone.delete_at(zone.index(self) || zone.length)
    to_zone.add self
    zone = to_zone
  end
  
  def colors
    color_identity
  end
  
  def to_s
    cost = " - #{mana_cost}"
    puts "#{id}: #{name} - #{card_type} #{cost}"
  end
  
  def playable?
    controller.can_play? self
  end
  
  def playable_zones
    [:hand] # + any zone added by ability
  end
  
  def max_in_deck
    return 1000 if types.include?('land') && supertypes.include?('basic')
    
    abilities.each do |ability|
      ability.effects.each_pair do |effect, args|
        return args if effect == 'max_in_deck'
      end
    end 
    return 4
  end
  
  TYPES = %w[land creature instant]
  def method_missing(method, *args, &block)
    type = method[/^is_([a-z]+)\?/, 1]
    if type && TYPES.include?(type)
      return types.include? type
    end
    
    super
  end
  
  def remove_type(type)
    type = type.to_s
    return false unless types.include? type
    
    # 506.4. A permanent is removed from combat if it’s a planeswalker that’s being attacked
    # and stops being a planeswalker, or stops being a creature.
    # 506.4d A permanent that’s both a blocking creature and a planeswalker that’s being attacked
    # is removed from combat if it stops being both a creature and a planeswalker.
    if type == 'creature'
      remove_from_combat unless types.include?('planeswalker') && attacked
    elsif type == 'planeswalker' && attacked
      remove_from_combat unless types.include?('creature') && blocking
    end
    
    types.delete type
  end
  
  def attack(target)
    self.attacking  = true
    target.attacked = true if target.is_a?(Card) # planeswalker
  end
  
  def block(target)
    self.blocking  = true
    target.blocked = true
  end
  
  private
  
  def remove_from_combat
    # A creature that’s removed from combat stops being an attacking, blocking, blocked, and/or unblocked creature.
    self.attacking = false
    self.blocking  = false
    self.blocked   = false
    self.unblocked = false
    
    # A planeswalker that’s removed from combat stops being attacked.
    self.attacked  = false
  end
  
  def set_default_state_values
    STATES.each do |state|
      self.send("#{state}=", false)
    end
  end
end

# A:SP$ ChangeZone | Cost$ 1 B | Origin$ Graveyard | Destination$ Hand | TargetMin$ 0 | TargetMax$ 2 | TgtPrompt$ Choose target creature card in your graveyard | ValidTgts$ Creature.YouOwn | SpellDescription$ Return up to two target creature cards from your graveyard to your hand, then discard a card. | SubAbility$ DBDiscard
# SVar:DBDiscard:DB$Discard | Defined$ You | NumCards$ 1 | Mode$ TgtChoose
# DeckHints:Ability$Graveyard & Ability$Discard
# DeckHas:Ability$Discard

