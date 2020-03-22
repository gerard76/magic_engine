class Zone
  attr_accessor :name, :cards, :game
  
  delegate *(Array.new.methods - Object.methods), to: :@cards
  
  def initialize(name, game)
    @name  = name
    @cards = []
    @game = game
  end
  
  def <<(card)
    add card
  end
  
  def add(card)
    cards << card
    card.zone = self
    
    if card.triggered_abilities.present? && name == :hand
      @game.register(card.triggered_abilities)
    end
    @game.trigger("enter_#{name}", source: card)
  end
  
  def delete(card)
    delete_at(index(card) || length)
  end
  
  def empty
    cards.each do |card|
      delete(card)
    end
  end
  
  def to_s
    cards.each &:to_s
  end
  
  %w(creature artifact enchantment land planeswalker).each do |type|
    define_method("#{type}s") do
      cards.filter do |card|
        card.send("is_#{type}?")
      end
    end
  end
end