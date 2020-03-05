FactoryBot.define do
  
  factory :mana_pool
  
  factory :zone do
    transient do
      player { build :player }
      name   { :foo          }
    end
    
    initialize_with { new(player, name) }
  end

  TYPES=%w(creature instant aorcery artifact)
  factory :card do
    types { TYPES.sample(1 + (rand(10) == 0 ? 1 : 0)) }
  end
  
  factory :deck do
    after(:build) do |deck, evaluator|
      40.times do
        deck.cards.build(attributes_for(:card))
      end
    end
  end
  
  factory :player do
    transient do
      deck { build :deck }
    end
    
    initialize_with { new(deck) }
  end
  
  factory :game do
    transient do
      players { [build(:player)] }
    end
    
    initialize_with { new(player) }
  end
  
  factory :ability do
    card
  end
  
end
