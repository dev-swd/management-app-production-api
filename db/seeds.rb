# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Employee.create!(
  number: '001',
  name: 'テスト太郎',
  name2: 'テストタロウ',
  birthday_y: 1977,
  birthday_m: 11,
  birthday_d: 1,
  address: '宮城県仙台市太白区',
  phone: '090-xxxx-xxxx'
)