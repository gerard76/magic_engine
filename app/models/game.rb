class Game
  include Workflow
  
  attr_accessor :stack,   # https://mtg.gamepedia.com/Stack
                :command  # https://mtg.gamepedia.com/Command
                
  attr_accessor :players, :active_player, :priority_player, :turn
  
  attr_accessor :active_triggers
  
  workflow do
    # Untap, Upkeep, Draw, Main1, Declare Attackers, Declare Blockers, Main2, End of Turn, and Cleanup
    state :untap do
      event :next_phase, transitions_to: :precombat
    end
    state :upkeep do
      event :next_phase, transitions_to: :combat
    end
    state :draw do
      event :next_phase, transitions_to: :postcombat
    end
    state :main1 do
      event :next_phase, transitions_to: :ending
    end
    state :attack do
      event :next_phase, transitions_to: :ending
    end
    state :block do
      event :next_phase, transitions_to: :ending
    end
    state :main2 do
      event :next_phase, transitions_to: :ending
    end
    state :end_of_turn do
      event :next_phase, transitions_to: :ending
    end
    state :cleanup do
      event :next_turn, transitions_to: :beginning
    end
    
    on_entry do |phase|
      trigger "beginning_of_#{phase}"
    end
    
    on_exit do |from, to|
      # 500.4 When a step or phase ends, any unused mana left in a player’s mana pool empties.
      @active_player.empty_mana_pool
      
      # 500.5 effects scheduled to last “until end of” that phase or step expire
      expire_effect(:end_of, from)
      
      trigger "end_of_#{phase}"
    end
  end
  
  def initialize(players)
    @turn    = 0
    @players = players
    
    @active_player   = players.sample # the one that starts
    @priority_player = @active_player
    
    @active_triggers = []
  end
  
  def run
    while playing?
      @active_player.draw unless turn == 0
      
      state_based_actions
      
      next_turn!
    end
  end
  
  def untap
    puts "untap"
    active_player.untap
    next_phase!
  end
  
  def upkeep
    puts "upkeep"
    active_player.upkeep
    next_phase!
  end
  
  def draw
    puts "draw"
    active_player.draw
    
    next_phase!
  end
  
  def main1
    puts "main1"
    next_phase!
  end
  
  def attack
    puts "attack"
    next_phase!
  end
  
  def block
    puts "block"
    next_phase!
  end
  
  def main2
    puts "main2"
    next_phase!
  end
  
  def end_of_turn
    puts "end of turn"
    next_phase!
  end
  
  def cleanup
    @active_player.cleanup
  end
  
  def next_turn
    puts "next turn"
    active_player = players[(players.index(active_player) + 1) % players.size]
  end
  
  def check_state_based_actions
    players.each do |player|
      # 704.5a If a player has 0 or less life, that player loses the game.
      player.lose if player.life == 0
      
      # 704.5c If a player has ten or more poison counters, that player loses the game.
      player.lose if player.poison_counter >= 10
      
      [:hand, :library, :graveyard, :exile, :battlefield].each do |zone_name|
        zone = player.send(zone_name)
        legendaries = []
        zone.each do |card|
          # 704.5d If a token is in a zone other than the battlefield, it ceases to exist
          zone.delete(card) if card.types.include?('token') && zone_name != :battlefield
          
          if zone_name == :battlefield
            # 704.5f If a creature has toughness 0 or less, it’s put into its owner’s graveyard
            # 704.5g If a creature has toughness greater than 0, and the total damage marked on it is greater than or equal to its toughness, that creature has been dealt lethal damage and is destroyed.
            if card.types.include?('creature') &&
                        (card.toughness <= 0 || 
                         card.damage >= card.toughness ||
                         card.deathtouch_damage > 0)
              card.move(card.owner.graveyard) 
            end
            
            # 704.5i If a planeswalker has loyalty 0, it’s put into its owner’s graveyard
            if card.types.include?('planeswalker') && card.loyalty <= 0
              card.move(card.owner.graveyard)
            end
            
            legendaries << card if card.supertypes.include?('legendary')
          end
        end
        
        # 704.5j If a player controls two or more legendary permanents with the same name, that player chooses one of them, and the rest are put into their owners’ graveyards.
        unless legendaries.uniq!.nil?
          # O(n^2) kan ook wel in O(n)
          duplicates = legendaries.select{|e| legendaries.count(e) > 1 }.uniq
          puts "pick the Legendary to keep #{duplicates.map(&:name)}"
        end
      end
    end
  end
  
  def expire_effect(lasts, phase)
    active_effects.reject! do |e|
      e.phase == phase && e.lasts == lasts
    end
  end
  
  def playing?
    playing = players.reject(&:lost?)
    return playing.size > 1 if players.size > 1
    playing.size == 1
  end
  
  def pass_priority
    # 704.3. Whenever a player would get priority, the game checks for any of the listed conditions for state-based actions
    check_state_based_actions
    priority_player = players[(players.index(priority_player) + 1) % players.size]
  end
  
  def activate_ability(card)
    # pretend a card only has 1 ability
    ability = card.abilities.first
    ability.pay_cost
    stack << ability
  end
  
  def trigger(name, args)
    active_triggers.filter(name).each do |trigger|
      trigger.ability.owner = trigger.source.owner
      stack << trigger.ability # should actually be put on stack the next time a player receives priority
      
      # 603.3b If multiple abilities have triggered since the last time a player received priority, each player, in APNAP order, puts triggered abilities they control on the stack in any order they choose. (See rule 101.4.) Then the game once again checks for and resolves state-based actions until none are performed, then abilities that triggered during this process go on the stack. This process repeats until no new state-based actions are performed and no abilities trigger. Then the appropriate player gets priority.
    end
  end
  
  def remove_triggers(triggers)
    triggers = [triggers] unless triggers.is_a? Array
    triggers.each do |trigger|
      active_triggers.delete trigger
    end
  end
end