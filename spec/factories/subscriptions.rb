FactoryBot.define do
  factory :subscription do
    user { nil }
    amount { "9.99" }
    status { "MyString" }
    stripe_subscription_id { "MyString" }
    currency { "MyString" }
    remarks { "MyText" }
  end
end
