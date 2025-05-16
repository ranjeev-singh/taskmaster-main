FactoryBot.define do
  factory :task do
    association :assigned_to, factory: :user
    association :assigned_by, factory: :user
    title { Faker::Lorem.sentence(word_count: 4) }
    description { Faker::Lorem.paragraph }
    due_date { Faker::Date.forward(days: 20) }
    status { %w[pending in_progress completed].sample }

    trait :pending do
      status { 'pending' }
    end

  end
end
