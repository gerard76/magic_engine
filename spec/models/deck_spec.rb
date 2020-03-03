require 'rails_helper'

describe Deck do
  let(:deck) { build :deck }
  let(:land) { build :card, types: ['Land'], supertypes: ['Basic'] }
  let(:creature) { build :card }
  let(:dwarves)  { build :card }
  
  describe '#valid?' do
    it 'returns false if you have more than 4 non-lands' do
      
      creature
      5.times { deck.cards << creature }
      expect(deck.valid?).to be_falsey
    end
    
    it 'returns true if you have more than 4 basic lands' do
      5.times { deck.cards << land }
      expect(deck.valid?).to be_truthy
    end
  end
end
