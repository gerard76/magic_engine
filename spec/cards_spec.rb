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
    # Shock deals 2 damage to any target.
    it 'hurts' do
      card = build :instant, name: 'Shock'
      card.abilities << build(:activated_ability,
          cost: { name: :mana, args: { color: :R, amount: 1 }},
          effect: { name: :damage, args: { amount: 2, target: { amount: 1, type: :any }}}
        )
      player.hand << card
      
      
      expect{ player.play_card(player.hand.last, player) }.to change{
        player.life }.by(-2)
    end
  end
  
  describe 'Akoum Refuge' do
    # Akoum Refuge enters the battlefield tapped.
    # When Akoum Refuge enters the battlefield, you gain 1 life.
    # {T}: Add {B} or {R}.
    
    let(:card) { build(:land, name: 'Akoum Refuge')}
    let(:tap1)  { build(:activated_ability,
                        cost:   { name: :tap },
                        effect: { name: :mana, args: { color: :R }})}
    let(:tap2)  { build(:activated_ability,
                        cost:   { name: :tap },
                        effect: { name: :mana, args: { color: :B }})}
    let(:gain_life) { build(:triggered_ability,
                             effect:  { name: :gain_life },
                             trigger: { event: :enter_battlefield })}
    let(:enter_tapped) { build(:triggered_ability,
                                effect:  { name: :state, args: [:tapped] },
                                trigger: { event: :enter_battlefield })}
                                
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
end