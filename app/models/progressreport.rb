class Progressreport < ApplicationRecord
  belongs_to :project
  has_many :phasecopies, dependent: :destroy
  has_many :taskcopies, dependent: :destroy
  has_many :evms, dependent: :destroy
  has_many :phaseactuals, dependent: :destroy
  has_many :taskactuals, dependent: :destroy
end
