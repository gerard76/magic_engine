class PlayerZone < Zone
  attr_accessor :owner
  
  def initialize(player, name)
    @owner = player
    
    super(name)
  end
  
  def add(card_or_cards)
    card_or_cards=[card_or_cards] unless card_or_cards.is_a?(Array)
    card_or_cards.each do |card|
      card.controller = owner
    end
    
    super card_or_cards
  end
end
