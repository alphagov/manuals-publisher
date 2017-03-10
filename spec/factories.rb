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

  factory :cma_editor, parent: :editor do
    organisation_slug "competition-and-markets-authority"
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
    document_id { BSON::ObjectId.new }
    sequence(:slug) { |n| "test-section-edition-#{n}" }
    sequence(:title) { |n| "Test Section Edition #{n}" }
    summary "My summary"
    body "My body"
  end

  factory :publication_log do
    sequence(:slug) { |n| "test-publication-log-#{n}" }
    sequence(:title) { |n| "Test Publication Log #{n}" }
    version_number { [1, 2, 3].sample }
    sequence(:change_note) { |n| "Change note #{n}" }
  end
end
