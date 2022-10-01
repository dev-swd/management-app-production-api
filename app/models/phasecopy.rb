class Phasecopy < ApplicationRecord
  belongs_to :progressreport
  has_one :phaseactual
end
