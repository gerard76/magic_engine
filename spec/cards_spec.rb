require 'rails_helper'

describe 'Cards' do
  let(:deck)   { build :deck }
  let(:player) { build :player, deck: deck }
  let(:game)   { build :game, players: [player] }
  let(:card)   { build :card }
  
  before do
    allow(player).to receive(:game).and_return(game)
  end
  
  describe 'Shock' do
    let(:card) { build :instant, name: 'Shock', owner: player }
    
    before do
      card.abilities << build(:activated_ability,
          cost: { mana: :R },
          effect: { damage: 2 }
        )
      player.hand << card
    end
    
    # Shock deals 2 damage to any target.
    it 'hurts' do
      expect{ player.play_card(player.hand.last, player) }.to change{
        player.life }.by(-2)
    end
  end
  
  describe 'Akoum Refuge' do
    # Akoum Refuge enters the battlefield tapped.
    # When Akoum Refuge enters the battlefield, you gain 1 life.
    # {T}: Add {B} or {R}.
    
    let(:card) { build(:land, name: 'Akoum Refuge', owner: player)}
    let(:tap1)  { build(:activated_ability,
                        cost: :tap,
                        effect: { mana: :R })}
    let(:tap2)  { build(:activated_ability,
                        cost: :tap,
                        effect: { mana: :B })}
    let(:gain_life) { build(:triggered_ability,
                             effect: :gain_life,
                             trigger: :enter_battlefield )}
    let(:enter_tapped) { build(:triggered_ability,
                                effect: :tapped,
                                trigger: :enter_battlefield )}
                                
    before do
      card.abilities += [tap1, tap2, gain_life, enter_tapped]
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
        player.mana_pool['R']
      }.by +1
    end
  end
  
  describe 'Jund Hackblade' do
    # As long as you control another multicolored permanent, Jund Hackblade gets +1/+1 and has haste.
    
    let(:card)   { build(:creature, name: 'Jund Hackblade', power: 2, 
                     toughness: 1, owner: player, mana_cost: '{B/G}{R}')}
    let(:static) { build(:static_ability,
                          effect: [ :haste, 
                                   { power: "+1" },
                                   { toughness: "+1" }],
                          trigger: { compare: [{count: [:control, :permanent, :multicolor]}, ">1"]} )}
                          
    before do
      card.abilities << static
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
end