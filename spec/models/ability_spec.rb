require 'rails_helper'

describe Ability do
  let(:player)  { build :player }
  let(:game)    { build :game, players: [player] }
  let(:card)    { build :card                }
  let(:ability) { build :ability, card: card }
  
  before do
    allow(player).to receive(:game).and_return game
  end
  
  describe '#play' do
    it 'does not add mana abilities to the stack' do
      card.controller = player
      ability.effect = { name: "mana", args: { "color" => "B", "amount"=>2 }}
      expect { ability.play }.to change{ player.mana_pool['B'] }.by(2)
    end
  end
  
  describe 'some random card implementations' do
    describe 'Shock' do
      it 'hurts' do
        card = build :instant, name: 'Shock'
        card.abilities << build(:ability,
            cost: { name: :mana, args: { color: :R, amount: 1 }},
            effect: { name: :damage, args: { amount: 2, target: { amount: 1, type: :any }}},
            activation: :activated
          )
        player.hand << card
        
        player.play_card(player.hand.last, player)
        expect{game.stack.resolve}.to change{player.life}.by(-2)
      end
    end
  end
  
end