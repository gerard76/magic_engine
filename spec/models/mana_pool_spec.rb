require 'rails_helper'

describe ManaPool, type: :model do
  let(:mana_pool) { ManaPool.new }
  
  describe '#can_pay?' do
    it 'returns true when the input is nil' do
      expect(mana_pool.can_pay?(nil)).to be_truthy
    end
    
    it 'returns true when there is enough mana to pay generic' do
      mana_pool.add(:B, 3)
      expect(mana_pool.can_pay?("{3}")).to be_truthy
    end
    
    it 'returns true when there is enough of each color' do
      mana_pool.add(:B, 2)
      mana_pool.add(:R, 1)
      mana_pool.add(:W, 200)
      expect(mana_pool.can_pay?("{B}{B}{R}{W}{W}{W}{W}{W}")).to be_truthy
    end
  end
end