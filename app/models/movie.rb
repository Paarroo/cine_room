class Movie < ApplicationRecord
  belongs_to :creator
  belongs_to :validated_by
end
