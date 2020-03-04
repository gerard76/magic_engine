class Zone
  attr_accessor :name, :cards
  
  delegate *(Array.new.methods - Object.methods), to: :@cards

  def initialize(name)
    @name = name
    @cards = []
  end
  
  def add(card_or_cards)
    card_or_cards=[card_or_cards] unless card_or_cards.is_a?(Array)
    card_or_cards.each do |card|
      cards << card
      card.zone = self
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