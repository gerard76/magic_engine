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
    next if ['UST', 'UNH'].incluce?(set.code)
    attributes = Card.new.attributes.keys - %w[id card_type types supertypes subtypes]
    card = Card.new
    card.card_type   = c.type
    card.types       = c.types.map(&:downcase)
    card.supertypes  = c.supertypes.map(&:downcase)
    card.subtypes    = c.subtypes.map(&:downcase)
    
    attributes.each do |a|
      card.write_attribute(a, c.send(a))
    end
    card.save
  end
  sleep 5 # lets be civil about this
end

#### Vanilla abilities:
# Land:
Card.where(types: '{land}', supertypes: '{basic}').order(:id).each do |card|
  puts "#{card.id} - #{card.subtypes}"
  color = card.colors.first || 'C'
  card.abilities << Ability.new(
      cost: { name: :tap, args: { target: :self },
      effect: { name: :mana, args: { color: color, amount: 1 }},
      activation: :activated
    )
end;true

Card.where(name: 'Shock').each do |card|
  card.abilities << Ability.new(
    cost: { name: :mana, args: { color: :R, amount: 1 }},
    effect: { name: :damage, args: { amount: 2, target: { amount: 1, type: :any }}},
    activation: :activated
  )
end