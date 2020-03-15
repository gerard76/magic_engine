require 'rails_helper'

describe Player do
  let(:player) { build :player }
  let(:game)   { build :game, players: [player] }
  
  before do
    allow(player).to receive(:game).and_return game
    allow(game).to receive(:priority_round).and_return true # prevent auto resolve
  end
  
  describe 'initialize' do
    it 'has an opening hand' do
      expect(player.hand.size).to be >= 0
    end
  end
  
  describe '#draw' do
    it 'draws from library' do
      library_card_count = player.library.size
      player.draw
      expect(player.library.size).to be < library_card_count
    end
    
    it 'draws to hand' do
      player.draw
      expect(player.hand.size).to be > 0
      expect(player.hand.first.zone.name).to eql(:hand)
    end
  end
  
  describe '#can_play?' do
    let(:mana_pool) { build :mana_pool }

    let(:zone)      { build :zone      }
    let(:card)      { build :card, zone: zone, owner: player }
    
    before do
      allow(player).to receive(:mana_pool).and_return(mana_pool)
      allow(mana_pool).to receive(:can_pay?).and_return true
      allow(card).to receive(:playable_zones).and_return([card.zone.name])
    end
    
    it 'returns true when all the planets align' do
      expect(player.can_play?(card)).to be_truthy
    end
    
    it 'returns false if the card is in a non-playable zone' do
      expect(card).to receive(:playable_zones).and_return([])
      expect(player.can_play?(card)).to be_falsey
    end
    
    it 'returns false if there is not enough mana' do
      expect(mana_pool).to receive(:can_pay?).and_return false
      
      expect(player.can_play?(card)).to be_falsey
    end
    
    it 'returns false if the player is not the controller of the card' do
      expect(card).to receive(:owner).and_return(build(:player))
      
      expect(player.can_play?(card)).to be_falsey
    end
  end
  
  describe '#play_card' do
    let(:card) { build :card, owner: player }
    
    it 'returns false if the card can not be played' do
      expect(player.play_card(card)).to be_falsey
    end
    
    context "card in hand" do
      before { player.hand << card }
      
      it 'moves the card from hand' do
        expect{player.play_card(player.hand.first)}.
          to change{player.hand.size}.from(8).to(7)
      end
    
      it 'moves the card to battlefield if its a land' do
        player.hand << build(:land, owner: player)
        expect{player.play_card(player.hand.last)}.
          to change{game.battlefield.size}.from(0).to(1)
      end
    
      it 'moves the card to the stack if it is not a land' do
        expect{ player.play_card(player.hand.last) }.
          to change{ game.stack.size }.from(0).to(1)
      end
    end
  end
  
  describe '#declare_attacker' do
    let(:planeswalker) { build :planeswalker                 }
    let(:attacker)     { build :creature, controller: player }
    let(:game)         { build :game, players: [player]      }
    
    before do
      allow(player).to receive(:game).and_return(game)
      game.send(:persist_workflow_state, :declare_attackers)
    end
    
    it 'returns true when all planets align' do
      expect(player.declare_attacker(attacker, planeswalker)).to be_truthy
    end
    
    it 'returns false when we are not in the declaring_attackers phase' do
      game.send(:persist_workflow_state, :untap)
      expect(player.declare_attacker(attacker, planeswalker)).to be_falsey
    end
    
    it 'returns false when creature has summoning sickness' do
      attacker.sick = true
      expect(player.declare_attacker(attacker, planeswalker)).to be_falsey
    end
    
    it 'returns true when creature has summoning sickness and haste' do
      attacker.sick  = true
      attacker.haste = true
      
      expect(player.declare_attacker(attacker, planeswalker)).to be_truthy
    end
  end
  
  describe '#declare_blocker' do
    let(:blocking_player) { build :player }
    let(:attacker)        { build :creature, attacking: blocking_player }
    let(:blocker)         { build :creature, controller: blocking_player }
    let(:game)            { build :game, players: [player, blocking_player] }
    
    before do
      allow(blocking_player).to receive(:game).and_return(game)
      game.send(:persist_workflow_state, :declare_blockers)
      game.active_player = player
    end
    
    it 'returns true when all planets align' do
      expect(blocking_player.declare_blocker(blocker, attacker)).to be_truthy
    end
  end
end