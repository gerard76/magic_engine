class Trigger < ApplicationRecord
  
  belongs_to :card
  
  attr_accessor :name
  
  #  A triggered ability is controlled by the player who controlled its source at the time it triggered
  attr_accessor :source
end