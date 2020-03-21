require 'rails_helper'

describe 'Cards' do
  let(:deck)   { build :deck }
  let(:player) { build :player, deck: deck }
  let(:game)   { build :game, players: [player] }
  let(:card)   { build :card }
  
  before do
    allow(player).to receive(:game).and_return(game)
    allow(player).to receive(:can_play?).and_return true
  end
  
  describe 'Shock' do
    # Shock deals 2 damage to any target
    let(:card) { build :instant, name: 'Shock', owner: player }
    
    before do
      card.abilities << build(:activated_ability,
                          cost:   { mana: { r: 1 } },
                          effect: { damage: 2 } )
      player.hand << card
    end
    
    it 'hurts' do
      expect{ player.play_card(player.hand.last, target: player) }.to change{
        player.life }.by(-2)
    end
    
    it 'ends up in the players graveyard' do
      player.play_card(card, target: player)
      expect(card.zone).to eql(player.graveyard)
    end
  end
  
  describe 'Akoum Refuge' do
    # Akoum Refuge enters the battlefield tapped.
    # When Akoum Refuge enters the battlefield, you gain 1 life.
    # {T}: Add {B} or {R}.
    let(:card) { build(:land, name: 'Akoum Refuge', owner: player) }
    
    before do
      card.abilities << build(:activated_ability,
                          cost: :tap,
                          effect: { mana: {r: "+1"}})
      card.abilities << build(:activated_ability,
                          cost: :tap,
                          effect: { mana: { b: "+1" }})
      card.abilities << build(:triggered_ability,
                          effect: { life: "+1" },
                          trigger: :enter_battlefield )
      card.abilities << build(:triggered_ability,
                          effect: { tapped: true },
                          trigger: :enter_battlefield )
      player.hand << card
    end
    
    it 'comes into play tapped' do
      player.play_card(card)
      expect(card).to be_tapped
    end
    
    it 'you gain 1 life when it enters the battlefield' do
      expect{ player.play_card(card) }.to change{ player.life }.by +1
    end
    
    it 'taps to produce mana' do
      expect{ card.abilities.first.activate }.to change {
        player.mana_pool['r']
      }.by +1
    end
  end
  
  describe 'Jund Hackblade' do
    # As long as you control another multicolored permanent, Jund Hackblade gets +1/+1 and has haste.
    let(:card)   { build(:creature, name: 'Jund Hackblade', power: 2, 
                     toughness: 1, mana_cost: '{B/G}{R}', owner: player)}
                     
    before do
      card.abilities << build(:static_ability,
                          effect: { 
                            haste: true,
                            power: "+1" ,
                            toughness: "+1"
                          },
                          condition: { 
                            compare: { 
                              this: { count: [:control, :permanent, :multicolor] }, 
                              that: ">1" }})
      game.battlefield << card
    end
    
    context "you do not control another multicolored permanent" do
      before do
        another = build :creature, controller: card.controller, mana_cost: '{R}'
        game.battlefield << another
      end
      
      it "is not buffed by default" do
        expect(card.current_power).to eql(2)
        expect(card.current_toughness).to eql(1)
      end
      
      it "does not have haste" do
        expect(card.haste?).to be_falsey
      end
    end
    
    context "you control another multicolored permanent" do
      before do
        another = build :creature, controller: card.controller, mana_cost: '{B/G}{R}'
        game.battlefield << another
      end
      
      it "is buffed" do
        expect(card.current_power).to eql(3)
        expect(card.current_toughness).to eql(2)
      end
      
      it "has haste" do
        expect(card.haste?).to be_truthy
      end
    end
  end
  
  describe 'Abyssal Specter' do
    # Flying
    # Whenever Abyssal Specter deals damage to a player, that player discards a card.
    let(:card)   { build(:creature, power: 2, owner: player) }
    
    before do
      card.abilities << build(:static_ability, effect: { flying: true }, card: card )
      card.abilities << build(:triggered_ability, card: card,
                          effect:  { discard: { amount: 1, player: :target } },
                          trigger: { damage:  { source: :self, target: :player }} )
                          
      player.hand << card
      player.play_card(card)
    end
    
    it 'flies' do
      expect(card.flying?).to be_truthy
    end
    
    it 'forces discard when damaging a player' do
      expect(player).to receive(:discard).with(1)
      card.assign_damage(player)
      game.pass_priority
    end
  end
  
  describe "Ambition's Cost" do
    # You draw three cards and you lose 3 life.
    let(:card) { build :sorcery, name: "Ambition's Cost", owner: player }
    
    before do
      card.abilities << build(:activated_ability,
                          cost:   { life: 3 },
                          effect: { draw: 3 } )
      player.hand << card
    end
    
    it 'costs 3 life' do
      expect{ player.play_card(card) }.to change{ player.life }.by(-3)
    end
    
    it 'allows you to draw 3 cards' do
      3.times { player.library << build(:card) }
      # play 1 draw 3
      expect{ player.play_card(card) }.to change{ player.hand.size }.by(2)
    end
    
    it 'ends up in the players graveyard' do
      player.play_card(card)
      expect(card.zone).to eql(player.graveyard)
    end
  end
  
  describe 'Angelic Page' do
    # Flying
    # {T}: Target attacking or blocking creature gets +1/+1 until end of turn.
    let(:card)    { build :creature, name: 'Angelic Page', owner: player, power: 1, toughness: 1 }
    let(:ability) { build(:activated_ability, cost: :tap,
                      effect: {
                        power:     "+1",
                        toughness: "+1" },
                      expire: :end_of_turn) }
    let(:creature) { build :creature, power: 1, toughness: 1, owner: player }
    
    before do
      card.abilities << ability
      player.hand << card
      player.play_card(card)
      ability.activate(target: creature)
    end
    
    it 'gives target creature +1/+1' do
      expect(creature.current_power).to eql(2)
      expect(creature.current_toughness).to eql(2)
    end
    
    it 'does not give give the card self +1' do
      expect(card.current_power.to_i).to be(1)
    end
    
    it 'stops pump when turn ends' do
      game.trigger(:end_of_turn)
      expect(creature.current_power).to eql(1)
    end
  end
  
  describe 'Ardent Militia' do
    # Vigilance
    let(:card) { build :creature, owner: player }
    
    before do
      card.abilities << build(:static_ability, effect: { vigilance: true })
    end
    
    it 'does not tap when attacking' do
      game.send(:persist_workflow_state, :declare_attackers)
      expect(player.declare_attacker(card, player)).to be_truthy
      expect(card).to_not be_tapped
      expect(card.attacking).to_not be_nil
    end
  end
  
  describe 'Avatar of Hope' do
    # If you have 3 or less life, this spell costs {6} less to cast.
    let(:card) { build(:creature, mana_cost: '{6}{W}{W}', owner: player) }
    
    before do
      card.abilities << build(:static_ability,
                          condition: {
                            compare: { 
                              this: :life,
                              that: "<=3"
                            }
                          },
                          effect: {
                            mana_cost: "-6"
                          })
    end
    
    it 'costs a lot' do
      expect(card.current_mana_cost.values.sum).to eql(8)
    end
    
    it 'is on sale' do
      player.life = 3
      expect(card.current_mana_cost.values.sum).to eql(2)
    end
  end
end
