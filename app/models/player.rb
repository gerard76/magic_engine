class Player
  
  DEFAULT_HAND_SIZE = 7
  STARTING_LIFE = 20
  
  #zones
  attr_accessor :deck, :hand, :library, :graveyard, :exiled, :battlefield
  
  attr_accessor :starting_hand_size, :maximum_hand_size, :life
  attr_accessor :mulligan_count
  
  attr_accessor :poison_counter, :mana_pool, :lost
  
  def initialize(deck)
    @deck           = deck
    @graveyard      = Zone.new(:graveyard)
    @exiled         = Zone.new(:exiled)
    @battlefield    = Zone.new(:battlefield)
    @hand           = Zone.new(:hand)
    @library        = Zone.new(:library)
    
    @mulligan_count = 0
    
    @poison_counter = 0
    @mana_pool      = ManaPool.new
    
    @starting_hand_size = DEFAULT_HAND_SIZE
    @maximum_hand_size  = DEFAULT_HAND_SIZE
    @life               = STARTING_LIFE
    
    @lose = false
    library.add(deck.cards.shuffle)
    draw(starting_hand_size)
  end
  
  def draw(amount = 1)
    # this should be a styate based action
    lose if @library.size < amount
    
    cards = @library.pop(amount)
    cards.each do |card|
      card.add_default_abilities
      card.move hand
    end
    cards
  end
  
  def mulligan
    @mulligan_count += 1
    @library = (library + hand).shuffle
    @hand    = draw(starting_hand_size)
    
    # ai: which cards to return?
    @library.unshift *@hand.pop(mulligan_count)
  end
  
  def lose
    @lost = true
    raise "I lose"
  end
  
  def lost?
    @lost
  end
  
  def undap
    battlefield.each do |card|
      card.undap
    end
  end
  
  def cast(card)
    mana_pool.pay_mana card.mana_cost
  end

  def can_play?(card)
    card.playable_zones.include?(card.zone.name) &&
      mana_pool.can_pay?(card.mana_cost)
  end
  
  def pay_mana(color, amount)
    mana_pool.pay(color, amount)
  end
  
  def empty_mana_pool
    mana_pool.empty
  end
end