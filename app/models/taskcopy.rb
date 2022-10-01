class Taskcopy < ApplicationRecord
  belongs_to :progressreport
  has_one :taskactual
end
