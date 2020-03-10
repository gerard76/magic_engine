require 'rails_helper'

describe Stack do
  let(:game)  { build :game }
  let(:stack) { game.stack }
  
  describe 'resolve' do
    before do
      stack.add build(:creature)
    end
    
    it 'puts a creature on the battlefield' do
      expect{stack.resolve}.to change{game.battlefield.size}.by(1)
    end
    
    it 'removes the card from stack after it resolves' do
      expect{stack.resolve}.to change{stack.size}.by(-1)
    end
  end
end
