require 'rails_helper'

describe Game do
  let(:deck) { build :deck        }
  let(:p1)   { Player.new(deck)   }
  let(:p2)   { Player.new(deck)   }
  let(:game) { Game.new([p1]) }
  
  
  describe '#playing?' do
    it 'returns true if more than one player has not lost' do
      expect(game.playing?).to be_truthy
    end
    
    it 'returns false if one player is left in a multiplayer game' do
      game = Game.new([p1, p2])
      expect(p2).to receive(:lost?).and_return true
      expect(game.playing?).to be_falsey
    end
  end
  
  describe '#play_card' do
    it 'returns false if the card can not be played' do
      card = build :card
      expect(game.play_card(card)).to be_falsey
    end
    
    it 'moves the card from hand' do
      expect{game.play_card(p1.hand.first)}.
        to change{p1.hand.size}.from(7).to(6)
    end
    
    it 'moves the card to battlefield' do
      expect{game.play_card(p1.hand.first)}.
        to change{p1.battlefield.size}.from(0).to(1)
    end
  end
end