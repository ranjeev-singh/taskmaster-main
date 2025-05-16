FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.password(min_length: 6) }
    jti { Faker::Internet.uuid }

    trait :manager do
      role { 'manager' }
    end

    trait :admin do
      role { 'admin' }
    end
  end
end
