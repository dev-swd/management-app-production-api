class Division < ApplicationRecord
  belongs_to :department
  has_many :approvalauths, dependent: :destroy
  has_many :employees, dependent: :nullify
end
