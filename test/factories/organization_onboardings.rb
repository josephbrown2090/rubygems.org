FactoryBot.define do
  factory :organization_onboarding do
    title { "Rubygems" }
    slug { "rubygems" }

    invitees do
      []
    end

    rubygems do
      []
    end

    created_by { 1 }

    trait :completed do
      status { :completed }
      onboarded_at { Time.zone.now }
    end
  end
end
