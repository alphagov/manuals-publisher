FactoryGirl.define do
  factory :user do
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:name) { |n| "Joe Bloggs #{n}" }
    sequence(:email) { |n| "joe#{n}@bloggs.com" }
    if defined?(GDS::SSO::Config)
      # Grant permission to signin to the app using the gem
      permissions { ["signin"] }
    end
  end

  factory :disabled_user, parent: :user do
    disabled true
  end

  factory :editor, parent: :user do
    permissions %w(signin editor)
  end

  factory :generic_writer, parent: :user do
    organisation_slug "ministry-of-tea"
  end

  factory :generic_editor, parent: :editor do
    organisation_slug "ministry-of-tea"
  end

  factory :generic_editor_of_another_organisation, parent: :editor do
    organisation_slug "another-organisation"
  end

  factory :gds_editor, parent: :user do
    permissions %w(signin gds_editor)
    organisation_slug "government-digital-service"
  end

  factory :section_edition do
    section_uuid { SecureRandom.uuid }
    sequence(:slug) { |n| "test-section-edition-#{n}" }
    sequence(:title) { |n| "Test Section Edition #{n}" }
    summary "My summary"
    body "My body"
    change_note "New section added"
  end

  factory :publication_log do
    sequence(:slug) { |n| "test-publication-log-#{n}" }
    sequence(:title) { |n| "Test Publication Log #{n}" }
    version_number { [1, 2, 3].sample }
    sequence(:change_note) { |n| "Change note #{n}" }
  end

  factory :manual_record do
    slug 'slug'
    manual_id 'abc-123'
    organisation_slug 'organisation_slug'

    after(:build) do |manual_record|
      manual_record.editions << FactoryGirl.build(:manual_record_edition)
    end

    trait :with_sections do
      after(:build) do |manual_record|
        manual_record.editions.each do |edition|
          section = FactoryGirl.create(:section_edition)
          edition.section_ids = [section.section_uuid]
        end
      end
    end

    trait :with_removed_sections do
      after(:build) do |manual_record|
        manual_record.editions.each do |edition|
          section = FactoryGirl.create(:section_edition)
          edition.removed_section_ids = [section.section_uuid]
        end
      end
    end
  end

  factory :manual_record_edition, class: 'ManualRecord::Edition' do
    title 'title'
    summary 'summary'
    body 'body'
    state 'state'
    version_number 1
    originally_published_at Time.now
    use_originally_published_at_for_public_timestamp true
  end
end
