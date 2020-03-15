class PlayerZone < Zone
  
  def initialize(player, name)
    @player = player
    
    super(name, game)
  end
  
  def add(card)
    super card
  end
  
  def game
    @player.game
  end
  
end
