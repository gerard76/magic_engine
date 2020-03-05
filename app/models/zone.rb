class Zone
  attr_accessor :name, :cards, :owner
  
  delegate *(Array.new.methods - Object.methods), to: :@cards
  
  def initialize(player, name)
    @name  = name
    @owner = player
    
    @cards = []
  end
  
  def <<(card_or_cards)
    add card_or_cards
  end
  
  def add(card_or_cards)
    card_or_cards=[card_or_cards] unless card_or_cards.is_a?(Array)
    card_or_cards.each do |card|
      cards << card
      card.zone = self
      card.controller = owner
    end
  end
  
  def delete(card)
    cards.delete(card)
  end
  
  def empty
    cards.each do |card|
      delete(card)
    end
  end
  
  def to_s
    cards.each &:to_s
  end
end