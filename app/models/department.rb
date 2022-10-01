class Department < ApplicationRecord
  has_many :divisions, dependent: :destroy
end
