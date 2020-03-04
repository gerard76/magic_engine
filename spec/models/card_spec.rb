require 'rails_helper'

describe Card do
  let(:card) { build :card }
  
  it 'has a default zone' do
    expect(card.zone).to be_a(Zone)
  end
  
  describe '#move' do
    let(:old_zone) { build :zone, name: :old_zone }
    let(:new_zone) { build :zone, name: :new_zone }
    
    before do
      card.zone = old_zone
      old_zone.add card
    end
    
    it 'can be found in old zone before the move' do
      expect(old_zone.cards).to include(card)
      expect(card.zone).to eql(old_zone)
      expect(card.zone.name).to eql(:old_zone)
    end
    
    it 'is not in the new zone before the move' do
      expect(new_zone.cards).to_not include(card)
    end
    
    it 'is removed from old zone' do
      card.move new_zone
      expect(old_zone.cards).to_not include(card)
    end
    
    it 'is added to the new zone' do
      card.move new_zone
      expect(new_zone.cards).to include(card)
      expect(card.zone).to eql(new_zone)

      expect(card.zone.name).to eql(:new_zone)
    end
    
    it 'does not clear all the cards from the old zone' do
      old_zone.add card
      card.move new_zone
      expect(old_zone.cards.size).to eql(1)
    end
  end
end