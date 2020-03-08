class Game
  include Workflow
  
  attr_accessor :stack,   # https://mtg.gamepedia.com/Stack
                :command  # https://mtg.gamepedia.com/Command
                
  attr_accessor :players, :active_player, :priority_player, :turn
  
  attr_accessor :active_triggers
  
  workflow do
    # Untap, Upkeep, Draw, Main1, Declare Attackers, Declare Blockers, Main2, End of Turn, and Cleanup
    state :untap do
      event :next_phase, transitions_to: :upkeep
    end
    state :upkeep do
      event :next_phase, transitions_to: :draw
    end
    state :draw do
      event :next_phase, transitions_to:  :main1
    end
    state :main1 do
      event :next_phase, transitions_to: :beginning_of_combat
    end
    
    ## combat phase
    state :beginning_of_combat do
      event :next_phase, transitions_to: :declare_attackers
    end
    
    state :declare_attackers do
      event :next_phase, transitions_to: :declare_blockers
    end
    
    state :declare_blockers do
      event :skip_combat, transitions_to: :end_of_combat
      event :next_phase, transitions_to: :combat_damage
    end
    
    state :combat_damage do
      event :next_phase, transitions_to: :end_of_combat
    end
    
    state :end_of_combat do
      event :next_phase, transitions_to: :main2
    end
    
    state :main2 do
      event :next_phase, transitions_to: :end_of_turn
    end
    state :end_of_turn do
      event :next_phase, transitions_to: :cleanup
    end
    state :cleanup do
      event :next_turn, transitions_to: :untap
    end
    
    on_entry do |phase|
      puts "Phase: #{phase}"
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
    players = [players] unless players.is_a?(Array)
    
    @turn    = 0
    players.each { |p| p.game = self }
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
  
  ### Phases
  def untap
    active_player.untap
    next_phase!
  end
  
  def upkeep
    active_player.upkeep
    next_phase!
  end
  
  def draw
    active_player.draw
    
    next_phase!
  end
  
  def main1
    next_phase!
  end
  
  def beginning_of_combat
    # 507.1 Chose opponent. That player becomes the defending player.
    # TODO
    
    # 507.2. The active player gets priority
    self.priority_player = active_player
    
    next_phase!
  end
  
  def declare_blockers
    # 508.8. If no creatures are declared as attackers or put onto the battlefield attacking
    # skip the declare blockers and combat damage steps.
    skip_combat! unless active_player.battlefield.find(&:attacking)
    next_phase!
  end
  
  def combat_damage
    attackers = active_player.battlefield.filter(&:attacking)
    
    attackers.each do |a|
      blocker = a.blocker
      if a.first_strike? || a.double_strike?
        a.assign_attack_damage
      elsif blocker.try(:first_strike?) || blocker.try(:double_strike?)
        blocker.assign_block_damage
      end
    end
    
    check_state_based_actions
    
    attackers.each do |a|
      next if a.lethal_damage?
      
      if !a.first_strike? || a.double_strike
        a.assign_attack_damage
      end
      
      blocker = a.blocker
      next if !blocker || blocker.zone.name != :battlefield
      
      if !blocker.first_strike? || blocker.double_strike?
        blocker.assign_block_damage
      end
    end
    
    check_state_based_actions
  end
  
  def end_of_combat
    # TODO
    # 511.2. Abilities that trigger “at end of combat” trigger as the end of combat step begins.
    # Effects that last “until end of combat” expire at the end of the combat phase.
    
    players.each(&:end_of_combat)
    
    next_phase!
  end
  
  def main2
    next_phase!
  end
  
  def end_of_turn
    next_phase!
  end
  
  def cleanup
    @active_player.cleanup
  end
  
  def next_turn
    active_player = players[(players.index(active_player) + 1) % players.size]
  end
  
  def check_state_based_actions
    players.each do |player|
      [:hand, :library, :graveyard, :exiled, :battlefield].each do |zone_name|
        zone = player.send(zone_name)
        legendaries = []
        zone.each do |card|
          # 704.5d If a token is in a zone other than the battlefield, it ceases to exist
          zone.delete(card) if card.is_token? && zone_name != :battlefield
          
          if zone_name == :battlefield
            # 704.5f If a creature has toughness 0 or less, it’s put into its owner’s graveyard
            # 704.5g If a creature has toughness greater than 0, and the total damage marked on it is greater than or equal to its toughness, that creature has been dealt lethal damage and is destroyed.
            if card.is_creature? && card.lethal_damage?
              card.move(card.owner.graveyard)
            end
            
            # 704.5i If a planeswalker has loyalty 0, it’s put into its owner’s graveyard
            if card.is_planeswalker? && card.loyalty <= 0
              card.move(card.owner.graveyard)
            end
            
            # count legendaries
            legendaries << card if card.is_legendary?
          end
        end
        
        # 704.5j If a player controls two or more legendary permanents with the same name, that player chooses one of them, and the rest are put into their owners’ graveyards.
        legenadaries = legendaries.tally
        legenadaries.reject { |k,v| v < 1}.each do |legendary|
          puts "remove one of the '#{legendary.name}' legendaries"
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
    playing = players.reject(&:dead?)
    return true if players.size == 1 && playing.size > 0
    
    playing.size > 1
  end
  
  def pass_priority
    # 704.3. Whenever a player would get priority, the game checks for any of the listed conditions for state-based actions
    check_state_based_actions
    priority_player = players[(players.index(priority_player) + 1) % players.size]
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