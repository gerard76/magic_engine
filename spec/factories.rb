FactoryBot.define do
  factory :mana_pool
  factory :zone do
    initialize_with { new(:foo) }
  end

  TYPES=%w[Creature Instant Sorcery Artifact]
  factory :card do
    types { TYPES.sample(1 + (rand(10) == 0 ? 1 : 0)) }
    zone  { build :zone }
  end
  
  factory :deck do
    after(:build) do |deck, evaluator|
      40.times do
        deck.cards.build(attributes_for(:card))
      end
    end
  end
  
  factory :player do
    initialize_with { new(build :deck) }
  end
  
  factory :game do
    initialize_with { new() }
    active_triggers { [] }
  end
  
  factory :ability do
    card
  end
end
