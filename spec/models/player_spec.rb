require 'rails_helper'

describe Player do
  let(:player) { build :player }
  let(:card)   { build :card   }
  
  describe '#can_play?' do
    let(:mana_pool) { build :mana_pool}
    
    before do
      allow(player).to receive(:mana_pool).and_return(mana_pool)
    end
    
    it 'returns false if the card is in a non-playable zone' do
      expect(card).to receive(:playable_zones).and_return([])
      
      expect(player.can_play?(card)).to be_falsey
    end
    
    it 'returns false if there is not enough mana' do
      expect(mana_pool).to receive(:can_pay?).and_return false
      expect(card).to receive(:playable_zones).and_return([card.zone.name])
      
      expect(player.can_play?(card)).to be_falsey
    end
    
    it 'returns true when the stars align' do
      expect(mana_pool).to receive(:can_pay?).and_return true
      expect(card).to receive(:playable_zones).and_return([card.zone.name])
      
      expect(player.can_play?(card)).to be_truthy
    end
  end
end