class Player
  
  DEFAULT_HAND_SIZE = 7
  STARTING_LIFE = 20
  
  attr_accessor :game
  #zones
  attr_accessor :deck, :hand, :library, :graveyard, :exiled, :battlefield
  
  attr_accessor :life
  attr_accessor :mulligan_count
  
  attr_accessor :poison_counter, :mana_pool, :lost
  
  def initialize(deck)
    @deck           = deck
    @graveyard      = Zone.new(self, :graveyard)
    @exiled         = Zone.new(self, :exiled)
    @battlefield    = Zone.new(self, :battlefield)
    @hand           = Zone.new(self, :hand)
    @library        = Zone.new(self, :library)
    
    @mulligan_count = 0
    
    @poison_counter = 0
    @mana_pool      = ManaPool.new
    
    @starting_hand_size = DEFAULT_HAND_SIZE
    @maximum_hand_size  = DEFAULT_HAND_SIZE
    @life               = STARTING_LIFE
    

    @cards_played_this_turn = []
    
    @lose = false
    library.add(deck.cards.shuffle)
    library.each { |card| card.owner = self; card.controller = self }
    
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
  
  def lose
    lost = true
    raise "I lose"
  end
  
  def lost?
    lost
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
    # 506.2. During the combat phase, the active player is the attacking player
    # creatures that player controls may attack
    return false unless game.active_player == self &&
      game.current_state == :declare_attackers &&
      card.controller == self &&
      card.is_creature? &&
      !card.tapped? &&
      (!card.sick? || card.haste?)
      
    card.attack(target)
  end
  
  def  declare_blocker(card, target)
    return false unless game.current_state == :declare_blockers
    
    card.block(target)
  end
  
  def play_card(card)
    return false unless can_play?(card)
    
    mana_pool.pay_mana(card.mana_cost)
    card.move battlefield
    card.sick = true if card.is_creature?
    
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
end