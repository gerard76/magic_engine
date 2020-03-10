class PlayerZone < Zone
  attr_accessor :owner
  
  def initialize(player, name)
    @owner = player
    
    super(name)
  end
  
  def add(card)
    card.controller = owner
    
    super card
  end
end
