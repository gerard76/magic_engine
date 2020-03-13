require 'rails_helper'

describe Stack do
  let(:game)     { build :game }
  let(:player)   { build :player }
  let(:zone)     { build :player_zone }
  let(:stack)    { game.stack }
  let(:creature) { build(:creature, owner: player, zone: zone) }
  
  describe 'resolve' do
    before do
      allow(game).to receive(:priority_round).and_return true # prevent auto resolve
      stack.items << creature
    end
    
    it 'puts a creature on the battlefield' do
      expect{ stack.resolve }.to change{ game.battlefield.size }.by(1)
    end
    
    it 'removes the card from stack after it resolves' do
      expect{ stack.resolve }.to change{ stack.size }.by(-1)
    end
  end
end
