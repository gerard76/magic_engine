class Player
  
  DEFAULT_HAND_SIZE = 7
  STARTING_LIFE = 20
  ZONES = %i(graveyard exiled hand library)
  
  attr_accessor :name, :game
  attr_accessor :triggers
  #zones
  attr_accessor :deck, *ZONES
  
  attr_accessor :life, :overdraw
  attr_accessor :mulligan_count
  
  attr_accessor :poison_counter, :mana_pool
  attr_accessor :cant_be_attacked
  
  def initialize(deck)
    @deck = deck
   
    @mulligan_count = 0
    
    @poison_counter = 0
    @mana_pool      = ManaPool.new
    
    @starting_hand_size = DEFAULT_HAND_SIZE
    @maximum_hand_size  = DEFAULT_HAND_SIZE
    @life               = STARTING_LIFE
    
    @cant_be_attacked = false
    @cards_played_this_turn = []
    
    @triggers = []
  end
  
  def start_game(game)
    @game = game
    ZONES.each do |zone_name|
      self.send("#{zone_name}=", PlayerZone.new(self, zone_name))
    end
    
    deck.cards.shuffle.each do |card|
      # 108.3. The owner of a card in the game is the player who started the game with it in their deck.
      card.owner = self
      library.add(card)
    end
    
    draw(@starting_hand_size)
  end
  
  def draw(amount = 1)
    # 121.4. A player who attempts to draw a card from a library with no cards in it loses the game the next time a player would receive priority. (This is a state-based action)
    overdraw = library.size < amount
    return if overdraw
    
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
  
  def discard(amount = 1)
    # TODO: player chose card
    graveyard << hand.pop
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
      card.owner == self &&
      (!card.is_land? || !!!@cards_played_this_turn.detect(&:is_land?)) &&
      ((!card.is_sorcery? && !card.is_instant?) || card.abilities.first.can_pay?)
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
  
  def play_card(card, **options)
    # if it turns out options are only used for ':target' I need to simplify
    # if they are used for something else I need to remove these remarks
    return false unless can_play?(card)
    
    mana_pool.pay_mana(card.mana_cost)
    
    card.controller = self
    
    if card.is_land?
      card.move game.battlefield
      add_triggers_to_stack if triggers.present?
    else
      card.options = options
      game.stack.add card
    end
    
    @cards_played_this_turn << card
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
    game.battlefield
  end
  
  def dead?
    # 704.5a If a player has 0 or less life, that player loses the game.
    return true if life <= 0
    # 704.5c If a player has ten or more poison counters, that player loses the game.
    return true if poison_counter >= 10
    
    return true if overdraw
  end
  
  def add_triggers_to_stack
    if triggers.size > 1
      # 603.3b If multiple abilities have triggered since the last time a player received priority, each player, in APNAP order, puts triggered abilities they control on the stack in any order they choose.
      # TODO: let player determine order
    end
    
    while trigger = triggers.pop
      # TODO: if trigger has cost, player needs to pony up
      
      # 603.3c If a triggered ability is modal, its controller announces the mode choice when putting the ability on the stack.
      # TODO: let player determine mode
      game.stack << trigger
    end
  end

  def cards
    all_cards = battlefield.cards
    ZONES.each do |zone_name|
      all_cards += self.send(zone_name).cards
    end
    all_cards
  end
end