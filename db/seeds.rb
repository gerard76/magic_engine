# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# imoprt all cards. Takes a while
sets = MTG::Set.all
sets[50..-1].each do |set|
  puts "#{set.code}: #{set.name}"
  next if ['KTK', '10E'].include? set.code
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
