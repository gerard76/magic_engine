class Player
  
  DEFAULT_HAND_SIZE = 7
  STARTING_LIFE = 20
  
  attr_accessor :game
  #zones
  attr_accessor :deck, :hand, :library, :graveyard, :exiled, :battlefield
  
  attr_accessor :life
  attr_accessor :mulligan_count
  
  attr_accessor :poison_counter, :mana_pool
  attr_accessor :cant_be_attacked
  
  def initialize(deck)
    @deck           = deck
   
    @mulligan_count = 0
    
    @poison_counter = 0
    @mana_pool      = ManaPool.new
    
    @starting_hand_size = DEFAULT_HAND_SIZE
    @maximum_hand_size  = DEFAULT_HAND_SIZE
    @life               = STARTING_LIFE
    
    @cant_be_attacked = false
    @cards_played_this_turn = []
    
    @lose = false
    
  def start_game(game)
    @game = game
    @graveyard = PlayerZone.new(self, :graveyard)
    @exiled    = PlayerZone.new(self, :exiled)
    @hand      = PlayerZone.new(self, :hand)
    @library   = PlayerZone.new(self, :library)
 
    deck.cards.shuffle.each { |card| library.add(card) }
    
    draw(@starting_hand_size)
  end
  
  def draw(amount = 1)
    # this should be a styate based action
    lose if library.size < amount
    
    cards = library.pop(amount)
    cards.each { |card| card.move hand }
    cards
  end
  
  def mulligan
    mulligan_count += 1
    library = (library + hand).shuffle
    hand    = draw(@starting_hand_size)
    
    # ai: which cards to return?
    library.unshift *hand.pop(mulligan_count)
  end
  
  def untap
    battlefield.each do |card|
      card.untap
      card.sick = false
    end
  end
  
  def can_play?(card)
    card.playable_zones.include?(card.zone&.name) &&
      mana_pool.can_pay?(card.mana_cost) &&
      card.controller == self &&
      (!card.is_land? || !!!@cards_played_this_turn.detect(&:is_land?))
  end
  
  def declare_attacker(card, target)
    # TODO
    # if there is only 1 possible 'target' we could automatically pick that
    
    # 506.2. During the combat phase, the active player is the attacking player
    # creatures that player controls may attack
    return false unless game.current_state == :declare_attackers
    return false unless target.is_a?(Player) || target.is_planeswalker?
    return false if game.active_player != self
    return false if card.controller != self
    return false if target.cant_be_attacked
    
    card.attack(target)
  end
  
  def declare_blocker(card, target)
    return false unless game.current_state == :declare_blockers
    return false if card.controller != self
    return false if game.active_player == self # active player is attacker not defender
    
    # TODO
    # add cost to block to tally
    # 509.1e If any of the costs require mana, the defending player then has a chance to activate mana abilities
    
    card.block(target)
  end
  
  def end_of_combat
    battlefield.each(&:end_of_combat)
  end
  
  def play_card(card, *args)
    return false unless can_play?(card)
    
    mana_pool.pay_mana(card.mana_cost)
    
    if card.is_land?
      card.move game.battlefield
    else
      card.args = args
      card.move game.stack
    end
    
    @cards_played_this_turn << card
    # active_triggers += card.triggers
  end
  
  def pay_mana(color, amount)
    mana_pool.pay(color, amount)
  end
  
  def cleanup
    @cards_played_this_turn = []
  end
  
  def empty_mana_pool
    mana_pool.empty
  end
  
  def assign_damage(power)
    self.life -= power
  end
  
  def battlefield
    game.battlefield.filter { |c| c.controller == self }
  end
  
  def dead?
    # 704.5a If a player has 0 or less life, that player loses the game.
    return true if life <= 0
    # 704.5c If a player has ten or more poison counters, that player loses the game.
    return true if poison_counter >= 10
  end
end