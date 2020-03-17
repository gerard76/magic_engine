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
      ability.effect = { mana: {B: 2 }}
      expect { ability.play }.to change{ player.mana_pool['b'] }.by(2)
    end
  end
  
end