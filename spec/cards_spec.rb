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
    # Shock deals 2 damage to any target.
    let(:card) { build :instant, name: 'Shock', owner: player }
    
    before do
      card.abilities << build(:activated_ability,
                          cost:   { mana: { r: 1 } },
                          effect: { damage: 2 } )
      player.hand << card
    end
    
    it 'hurts' do
      expect{ player.play_card(player.hand.last, player) }.to change{
        player.life }.by(-2)
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
      # damage komt bij triggers van controller, maar die gaan niet op de stack
      expect(player).to receive(:discard).with(1)
      card.assign_damage(player)
      game.pass_priority
    end
  end
end