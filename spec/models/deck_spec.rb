require 'rails_helper'

describe Deck do
  let(:deck) { build :deck }
  let(:land) { build :card, types: ['Land'], supertypes: ['Basic'] }
  let(:creature) { build :card }
  
  describe 'validations' do
    it 'does not validate if you have more than 4 non-lands' do
      5.times { deck.cards << creature }
      expect(deck.valid?).to be_falsey
    end
    
    it 'validates if you have more than 4 basic lands' do
      5.times { deck.cards << land }
      expect(deck.valid?).to be_truthy
    end
    
    it 'allows more cards that have a larger max_in_deck ability' do
      dwarves = build :card, name: 'Seven Dwarves'
      dwarves.abilities.build(effects: { max_in_deck: 7 })
      5.times { deck.cards << dwarves }
      expect(deck.valid?).to be_truthy
    end
  end
end
