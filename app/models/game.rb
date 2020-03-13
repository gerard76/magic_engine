class Game
  include Workflow
  
  attr_accessor :battlefield,
                :stack,  # https://mtg.gamepedia.com/Stack
                :command # https://mtg.gamepedia.com/Command
                
  attr_accessor :players, :active_player, :priority_player, :turn
  
  attr_accessor :triggers
  
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
    @turn    = 0
    
    @stack = Stack.new(self)
    
    @triggers  = []
    @battlefield = Zone.new(:battlefield, self)
    
    ## PLAYERS:
    @players = players
    players.each { |p| p.start_game(self) }
    @active_player   = players.sample # the one that starts
    @priority_player = @active_player
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
    attackers = battlefield.filter(&:attacking)
    attackers.each do |a|
      blocker = a.blocker
      if a.strikes_first?
        a.assign_attack_damage
      elsif blocker.try(:first_strike?) || blocker.try(:double_strike?)
        blocker.assign_block_damage
      end
    end
    
    check_state_based_actions
    
    attackers.each do |a|
      next if a.lethal_damage?
      
      if !a.strikes_first?
        a.assign_attack_damage
      end
      
      blocker = a.blocker
      next if !blocker || blocker.zone.name != :battlefield
      
      if !blocker.strikes_first?
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
    # we need to dup this array because we're deleting
    # elements from it when moving cards to another zone
    battlefield.cards.dup.each do |card|
      # 704.5f If a creature has toughness 0 or less, it’s put into its owner’s graveyard
      # 704.5g If a creature has toughness greater than 0, and the total damage marked on it
      # is greater than or equal to its toughness, that creature has been dealt lethal damage and is destroyed.
      if card.is_creature? && card.lethal_damage?
        card.move(card.owner.graveyard)
      end
      
      # 704.5i If a planeswalker has loyalty 0, it’s put into its owner’s graveyard
      if card.is_planeswalker? && card.loyalty <= 0
        card.move(card.owner.graveyard)
      end
    end
    
    # 704.5j If a player controls two or more legendary permanents with the same name
    # that player chooses one of them, and the rest are put into their owners’ graveyards.
    players.each do |player|
      legendaries = player.battlefield.filter(&:is_legendary?)
      legendaries = legendaries.tally
      
      legendaries.reject { |legendary, count| count < 1}.each do |legendary|
        puts "remove one of the '#{legendary.name}' legendaries"
      end
    end
    
    players.each do |player|
      [:hand, :library, :graveyard, :exiled].each do |zone_name|
        zone = player.send(zone_name)
        zone.each do |card|
          # 704.5d If a token is in a zone other than the battlefield, it ceases to exist
          zone.delete(card) if card.is_token?
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
  
  def priority_round
    current_player = priority_player
    while pass_priority != current_player; end
    
    # 405.5. When all players pass in succession, the top (last-added) spell or ability on the stack resolves. If the stack is empty when all players pass, the current step or phase ends and the next begins.
    if stack.size > 0
      stack.resolve
    else
      next_phase!
    end
  end
  
  def pass_priority
    # 704.3. Whenever a player would get priority, the game checks for any of the listed conditions for state-based actions
    check_state_based_actions
    # byebug
    self.priority_player = players[(players.index(priority_player) + 1) % players.size]
    
    # 603.3. Once an ability has triggered, its controller puts it on the stack as an object that’s not a card the next time a player would receive priority.
    priority_player.add_triggers_to_stack if priority_player.triggers.present?
    
    # 603.3b If multiple abilities have triggered since the last time a player received priority, each player, in APNAP order, puts triggered abilities they control on the stack in any order they choose. (See rule 101.4.) Then the game once again checks for and resolves state-based actions until none are performed, then abilities that triggered during this process go on the stack. This process repeats until no new state-based actions are performed and no abilities trigger. Then the appropriate player gets priority.
    priority_round if players.any? { |p| p.triggers.present? }
    priority_player
  end
  
  def trigger(event, *args)
    triggers.dup.each do |ability|
      # look for registered triggered abilities that should trigger now
      if ability.trigger['event'] == event.to_s
        
        # 603.3a A triggered ability is controlled by the player who controlled its source at the time it triggered
        ability.controller = ability.card.controller
        ability.controller.triggers << ability
        triggers.delete(ability)
      end
      
      # look for triggers that should expire now
      if ability.expire == event.to_s
        triggers.delete(ability)
      end
    end
    
  end
  
  def register(triggered_ability)
    triggered_ability = [triggered_ability] unless triggered_ability.is_a?(Array)
    self.triggers += triggered_ability
  end
end