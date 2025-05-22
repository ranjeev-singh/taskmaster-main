FactoryBot.define do
  factory :email_notification do
    email { "MyString" }
    subject { "MyString" }
    body { "MyText" }
  end
end
