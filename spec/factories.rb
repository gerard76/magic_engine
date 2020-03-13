FactoryBot.define do
  
  factory :mana_pool
  
  factory :zone do
    transient do
      name   { :foo          }
    end
    
    initialize_with { new(name) }
  end
  
  factory :player_zone do
    transient do
      player { build :player }
      name   { :foo          }
    end
    
    initialize_with { new(player, name) }
  end
  
  factory :stack do
    transient do
      game   { build :game }
    end
    intialize_with { new(game) }
  end
  
  factory :card do
    factory :planeswalker do
      types { [:planeswalker] }
    end
    
    factory :creature do
      types { [:creature] }
      power { rand(0..5) }
      toughness { rand(1..5) }
    end
    
    factory :land do
      types { [:land] }
    end
    
    factory :instant do
      types { [:instant] }
    end
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
    
    initialize_with { new(players) }
  end
  
  factory :ability do
    card
    
    factory :static_ability do
      activation { :static }
    end
    
    factory :triggered_ability do
      activation { :triggered }
    end
    
    factory :activated_ability do
      activation { :activated }
    end
  end
  
end
