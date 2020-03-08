require 'rails_helper'

describe Game do
  let(:deck) { build :deck        }
  let(:p1)   { Player.new(deck)   }
  let(:p2)   { Player.new(deck)   }
  let(:game) { Game.new([p1, p2]) }
  
  
  describe '#playing?' do
    it 'returns true if more than one player is not dead' do
      expect(game.playing?).to be_truthy
    end
    
    it 'returns false if one player is left in a multiplayer game' do
      game = Game.new([p1, p2])
      expect(p2).to receive(:dead?).and_return true
      expect(game.playing?).to be_falsey
    end
  end
  
  describe '#combat_damage' do
    let(:attacker) { build :creature, power: 4, toughness: 1, attacking: p2, owner: p1      }
    let(:blocker)  { build :creature, power: 1, toughness: 1, blocking: attacker, owner: p2 }
    
    before do
      game.active_player = p1
      p1.battlefield << attacker
      p2.battlefield << blocker

      attacker.attack p2
    end
    
    context 'blocked' do
      before do
        blocker.block attacker
      end
      
      it 'allows mutual assured destruction' do
        game.combat_damage
      
        expect(attacker.zone.name).to eql(:graveyard)
        expect(blocker.zone.name).to eql(:graveyard)
      end
      
      it 'does not damage the player if blocked' do
        expect{ game.combat_damage }.to_not change{ p2.life }
      end
      
      it 'damages the player with trample' do
        attacker.trample = true
        expect{ game.combat_damage }.to change{ p2.life }.by(-3)
      end
      
      it 'kills the weak' do
        attacker.toughness = 10
        game.combat_damage
      
        expect(attacker.zone.name).to eql(:battlefield)
        expect(blocker.zone.name).to eql(:graveyard)
      end
    end
    
    it 'damages the player if not blocked' do
      expect{ game.combat_damage }.to change{ p2.life }.by(-4)
    end
    
    it 'kills the player and wins the game' do
      p2.life = 4
      game.combat_damage
      
      expect(p2.dead?).to be_truthy
      expect(game.playing?).to be_falsey
    end
  end
end