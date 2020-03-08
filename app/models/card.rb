class Card < ApplicationRecord
  
  ### STATES:
  
  STATES = %i(
    face_down
    tapped
    sick
    attacking
    attacker
    blocking
    blocker
    unblocked
    
    haste
    unblockable
    flying
    reach
    shadow
    daunt
    cant_block
    
    trample
    double_strike
    first_strike
    deathtouch
    
    cant_be_attacked
  )
  
  # TODO
  # think about 'cant_be_attacked' that is for planeswalkers and players only
  
  attr_accessor *STATES
  after_initialize :set_default_values
  
  STATES.each do |state|
    define_method("#{state}?") { !!self.send(state) }
  end

  attr_reader  :controller
  attr_accessor :owner, :zone
  attr_accessor :damage, :deathtouch_damage
  
  has_many :triggers
  has_many :abilities
  
  def tap_it
    return false if tapped || (sick && !haste)
    
    abilities.triggered.where("cost ->> 'tap' = 'self'" ).each(&:execute) # triggered abilities
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
    return 1000 if is_land? && is_basic?
    
    abilities.static.each do |ability|
      ability.effects.each_pair do |effect, args|
        return args if effect == 'max_in_deck'
      end
    end 
    return 4
  end
  
  #### TYPES:
  
  def method_missing(method, *args, &block)
    type = method[/^is_([a-z]+)\?/, 1]
    if type
      return true if types.include? type
      return true if supertypes.include? type
      return true if subtypes.include? type
      return false
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
      remove_from_combat unless is_planeswalker? && attacker
    elsif type == 'planeswalker' && attacker
      remove_from_combat unless is_creature? && blocking
    end
    
    types.delete type
  end
  
  ### COMBAT:
  
  def attack(target)
    return false unless is_creature?
    return false if tapped
    return false if sick && !haste
    
    self.attacking  = target
    target.attacker = self if target.is_a?(Card) # planeswalker
    
    # 508.1f The active player taps the chosen creatures
    tap_it
    
    # TODO
    # trigger on declaring attacker
  end
  
  def block(target)
    return false if target.unblockable?
    return false if blocking # max 1 block per card
    return false if tapped # 509.1a The chosen creatures must be untapped
    return false if target.flying && !(self.reach || self.flying)
    return false if target.daunt && power <= 2
    return false if cant_block
    return false unless target.shadow == self.shadow
    return false unless target.attacking
    
    self.blocking  = target
    target.blocker = self
    
    # TODO
    # 702.129a Afflict is a triggered ability. “Afflict N” means “Whenever this creature becomes blocked
    # defending player loses N life.”
    
    true
  end
  
  def assign_attack_damage
    damage = current_power
    if blocker # attacker is blocked
      
      # 510.1c A blocked creature assigns its combat damage to the creatures blocking it.
      # If no creatures are currently blocking it, it assigns no combat damage.
      if blocker.blocking == self # blocker is still blocking
        damage -= assign_damage(blocker)
      end
    end
    
    if !blocker || trample
      attacking.assign_damage(damage) # damage player or planeswalker
    end
  end
   
  def assign_block_damage
    if blocking.attacking # attacker is still attacking player or planeswalker
      assign_damage(blocking)
    end
  end
  
  def assign_damage(victim)
    if victim.is_planeswalker?
      victim.loyalty -= current_power
    elsif victim.is_a?(Player)
      victim.assign_damage(current_power)
    else
      damage_type = deathtouch? ? :deathtouch_damage : :damage
      amount = [current_power, victim.current_toughness].min
      victim.send("#{damage_type}=", amount)
    end
  end
  
  def lethal_damage?
    return true if current_toughness <= 0
    return true if damage >= current_toughness
    return true if deathtouch_damage > 0
    return true if is_planeswalker? && loyalty <= 0
    
    false
  end
  
  def end_of_combat
    self.attacking = false
    self.attacker  = false
    self.blocking  = false
    self.blocker   = false
    self.unblocked = false
  end
  
  def current_power
    # TODO
    # this is the place to look at counters and such
    # for now:
    power.to_i
  end
  
  def current_toughness
    # TODO
    # this is the place to look at counters and such
    # for now:
    toughness.to_i
  end
  
  private
  
  def remove_from_combat
    # A creature that’s removed from combat stops being an attacking, blocking, blocked, and/or unblocked creature.
    end_of_combat
  end
  
  def set_default_values
    STATES.each do |state|
      self.send("#{state}=", false)
    end
    
    self.damage =0
    self.deathtouch_damage = 0
  end
end

# A:SP$ ChangeZone | Cost$ 1 B | Origin$ Graveyard | Destination$ Hand | TargetMin$ 0 | TargetMax$ 2 | TgtPrompt$ Choose target creature card in your graveyard | ValidTgts$ Creature.YouOwn | SpellDescription$ Return up to two target creature cards from your graveyard to your hand, then discard a card. | SubAbility$ DBDiscard
# SVar:DBDiscard:DB$Discard | Defined$ You | NumCards$ 1 | Mode$ TgtChoose
# DeckHints:Ability$Graveyard & Ability$Discard
# DeckHas:Ability$Discard

