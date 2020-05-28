FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:name) { |n| "Joe Bloggs #{n}" }
    sequence(:email) { |n| "joe#{n}@bloggs.com" }
    if defined?(GDS::SSO::Config)
      # Grant permission to signin to the app using the gem
      permissions { %w[signin] }
    end
  end

  factory :disabled_user, parent: :user do
    disabled { true }
  end

  factory :editor, parent: :user do
    permissions { %w[signin editor] }
  end

  factory :generic_writer, parent: :user do
    organisation_slug { "ministry-of-tea" }
  end

  factory :generic_editor, parent: :editor do
    organisation_slug { "ministry-of-tea" }
  end

  factory :generic_editor_of_another_organisation, parent: :editor do
    organisation_slug { "another-organisation" }
  end

  factory :gds_editor, parent: :user do
    permissions { %w[signin gds_editor] }
    organisation_slug { "government-digital-service" }
  end

  factory :section_edition do
    section_uuid { SecureRandom.uuid }
    sequence(:slug) { |n| "test-section-edition-#{n}" }
    sequence(:title) { |n| "Test Section Edition #{n}" }
    summary { "My summary" }
    body { "My body" }
    change_note { "New section added" }
  end

  factory :publication_log do
    sequence(:slug) { |n| "test-publication-log-#{n}" }
    sequence(:title) { |n| "Test Publication Log #{n}" }
    version_number { [1, 2, 3].sample }
    sequence(:change_note) { |n| "Change note #{n}" }
  end

  factory :manual do
    slug { "manual-slug" }

    initialize_with do
      Manual.new(attributes)
    end
  end

  factory :manual_record do
    slug { "slug" }
    manual_id { "abc-123" }
    organisation_slug { "organisation_slug" }

    after(:build) do |manual_record|
      manual_record.editions << FactoryBot.build(:manual_record_edition)
    end

    trait :with_sections do
      after(:build) do |manual_record|
        manual_record.editions.each do |edition|
          section = FactoryBot.create(:section_edition)
          edition.section_uuids = [section.section_uuid]
        end
      end
    end

    trait :with_removed_sections do
      after(:build) do |manual_record|
        manual_record.editions.each do |edition|
          section = FactoryBot.create(:section_edition)
          edition.removed_section_uuids = [section.section_uuid]
        end
      end
    end
  end

  factory :manual_record_edition, class: "ManualRecord::Edition" do
    title { "title" }
    summary { "summary" }
    body { "body" }
    state { "state" }
    version_number { 1 }
    originally_published_at { Time.zone.now }
    use_originally_published_at_for_public_timestamp { true }
  end

  factory :organisation do
    title { "Cabinet Office" }
    web_url { "https://www.gov.uk/government/organisations/cabinet-office" }
    abbreviation { "CO" }
    content_id { "d94d63a5-ce8e-40a1-ab4c-4956eab27259" }
  end

  factory :link_check_report do
    batch_id { 1 }
    status { "in_progress" }
    completed_at { Time.zone.now }
    links { [FactoryBot.build(:link)] }

    trait :completed do
      status { "completed" }
    end

    trait :with_broken_links do
      links { [FactoryBot.build(:link, :broken)] }
    end

    trait :with_pending_links do
      transient do
        link_uris { [] }
      end

      links do
        link_uris.map { |uri| FactoryBot.build(:link, :pending, uri: uri) }
      end
    end
  end

  factory :link do
    uri { "http://www.example.com" }
    status { "ok" }

    trait :broken do
      status { "broken" }
    end

    trait :pending do
      status { "pending" }
    end
  end
end
