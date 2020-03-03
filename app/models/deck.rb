class Deck < ApplicationRecord

  has_many :deck_cards
  has_many :cards, through: :deck_cards

  validate :card_count
  
  def add(card)
    self.cards << card
  end
  
  def size
    card_count
  end
  
  def card_count
    cards.tally.each do |card, count|
      errors.add(:base, "Too many #{card.name}'s in deck") if count > card.max_in_deck
    end
    
    true
  end
end