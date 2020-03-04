require 'rails_helper'

describe Ability do
  let(:player)  { build :player              }
  let(:card)    { build :card                }
  let(:ability) { build :ability, card: card }
  
  describe '#excecute' do
    it 'adds mana to controllers pool' do
      card.controller = player
      ability.effects = {"mana"=>{"color"=>"B", "amount"=>2}}
      expect { ability.execute }.to change{ player.mana_pool['B'] }.by(2)
    end
  end
end