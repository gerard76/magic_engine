class Stack < Zone
  
  def initialize(game)
    @game = game
    super :stack
  end
  
  def add(card)
    super card
    @game.priority_round
  end
  
  def resolve
    cards.each do |card|
      resolve_card(card)
    end
  end
  
  def resolve_card(card)
    if card.is_instant? || card.is_sorcery?
      card.abilities.first.resolve # remove all but the chosen ability from the card when put on stack
    else
      card.sick = true if card.is_creature?
      card.move @game.battlefield
    end
    
    self.delete card
    @game.priority_round
  end
  
end
