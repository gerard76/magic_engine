# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# imoprt all cards. Takes a while
MTG::Set.all.each do |set|
  puts "#{set.code}: #{set.name}"
  MTG::Card.where(set: set.code).all.each do |c|
    attributes = Card.new.attributes.keys - %w[id card_type]
    card = Card.new
    card.card_type = c.type
    attributes.each do |a|
      card.write_attribute(a, c.send(a))
    end
    card.save
  end
  sleep 5 # lets be civil about this
end

#### Vanilla abilities:
# Land:
Card.where(types: '{Land}', supertypes: '{Basic}').order(:id).each do |card|
  puts "#{card.id} - #{card.subtypes}"
  color = card.color.first || 'C'
  card.abilities << Ability.new(cost: { tap: :self }, effects: { mana: { color: card, amount: 1 }})
end;true
