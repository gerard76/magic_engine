class Deck < ApplicationRecord

  has_many :deck_cards
  has_many :cards, through: :deck_cards

  def add(card)
    self.cards << card
  end
  
  def size
    card_count
  end
  
  def valid?
    cards.tally.each do |card, count|
      return false if count > card.max_in_deck
    end
    true
  end
end