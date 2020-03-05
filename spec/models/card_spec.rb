require 'rails_helper'

describe Card do
  let(:card) { build :card }

  it 'has sane defaults' do
    expect(card.tapped).to be_falsey
    expect(card.sick).to be_falsey
    expect(card.face_down).to be_falsey
  end
  
  describe '#tap_it' do
    it 'taps' do
      expect{card.tap_it}.to change{card.tapped}.to(true).from(false)
    end
    
    it 'does not allow tapping of a tapped card' do
      card.tap_it
      expect(card.tap_it).to be_falsey
    end
    
    it 'does not allow tapping of a sick card' do
      card.sick = true
      expect(card.tap_it).to be_falsey
    end
  end
  
  describe '#is_<type>?' do
    it 'returns true when types includes <type>' do
      card.types = ['Land']
      expect(card.is_land?).to be_truthy
    end
    
    it 'returns false when types does not include <type>' do
      card.types = ['Creature']
      expect(card.is_land?).to be_falsey
    end
  end
  
  describe '#untap' do
    it 'does not allow untapping of an untapped card' do
      card.untap
      expect(card.untap).to be_falsey
    end
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