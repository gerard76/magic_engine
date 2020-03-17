class Stack
  attr_accessor :items, :game
  
  delegate *(Array.new.methods - Object.methods), to: :@items
  
  def initialize(game)
    @game = game
    @items = []
  end
  
  def <<(item)
    add item
  end
  
  def add(item)
    items << item
    
    if item.is_a?(Card)
      item.zone.delete(item)
      item.zone = self
    end
    
    @game.priority_round
  end
  
  def delete(item)
    delete_at(index(item) || length)
  end
  
  def resolve
    while item = items.pop
      if item.is_a?(Card)
        resolve_card(item)
      else
        item.resolve
      end
    end
    
    @game.priority_round
  end
  
  def resolve_card(card)
    if card.is_instant? || card.is_sorcery?
      card.abilities.first.resolve # remove all but the chosen ability from the card when put on stack
      # TODO: then goto graveyard?
    else
      @game.battlefield << card
    end
  end
end
