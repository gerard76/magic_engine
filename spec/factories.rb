FactoryBot.define do
  # factory :mana_pool do
  # end
  #
  TYPES=%w[Creature Instant Sorcery Artifact]
  factory :card, class: "Card" do
    types { TYPES.sample(1 + (rand(10) == 0 ? 1 : 0)) }
    name { 'foo' }
  end
  
  factory :deck do
    after(:build) do |deck, evaluator|
      40.times do
        deck.cards.build(attributes_for(:card))
      end
    end
  end
end
