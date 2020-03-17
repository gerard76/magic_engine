require 'rails_helper'

describe ManaPool, type: :model do
  let(:mana_pool) { ManaPool.new }
  
  describe '#can_pay?' do
    it 'returns true when the input is nil' do
      expect(mana_pool.can_pay?(nil)).to be_truthy
    end
    
    it 'returns true when there is enough mana to pay generic' do
      mana_pool.add(:c, 3)
      expect(mana_pool.can_pay?("{3}")).to be_truthy
    end
    
    it 'returns true when there is enough of each color' do
      mana_pool.add(:b, 2)
      mana_pool.add(:r, 1)
      mana_pool.add(:w, 200)
      expect(mana_pool.can_pay?("{B}{B}{R}{W}{W}{W}{W}{W}")).to be_truthy
    end
  end
  
  describe '#pay_mana' do
    it 'subtracts the mana from the pool' do
      mana_pool['b'] = 10
      expect{ mana_pool.pay_mana('{B}{B}') }.to change{ mana_pool['b'] }.by(-2)
    end
    
    it 'favors colorless mana when paying generic' do
      mana_pool['b'] = 10
      mana_pool['c'] = 10
      expect{ mana_pool.pay_mana('{3}') }.to change{ mana_pool['c'] }.by(-3)
      expect(mana_pool['b']).to eql(10)
    end
  end
  
end