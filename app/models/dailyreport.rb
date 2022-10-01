class Dailyreport < ApplicationRecord
  has_many :workreports, dependent: :destroy
end
