require "state_machine"

class SectionEdition
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "manual_section_editions"

  field :section_uuid,         type: String
  field :version_number,       type: Integer, default: 1
  field :title,                type: String
  field :slug,                 type: String
  field :summary, type: String
  field :body, type: String
  field :state, type: String
  field :change_note, type: String
  field :minor_update, type: Boolean
  field :visually_expanded, type: Boolean, default: false
  field :exported_at, type: Time

  validates :section_uuid, presence: true
  validates :slug, presence: true

  embeds_many :attachments, cascade_callbacks: true

  state_machine initial: :draft do
    event :publish do
      transition draft: :published
    end

    event :archive do
      transition all => :archived, :unless => :archived?
    end
  end

  scope :all_for_section,
        lambda { |section_uuid|
          where(section_uuid: section_uuid)
        }

  scope :all_for_sections,
        lambda { |*section_uuids|
          where(:section_uuid.in => section_uuids)
        }

  scope :with_slug_prefix, ->(slug) { where(slug: /^#{slug}.*/) }

  index section_uuid: 1
  index state: 1
  index updated_at: 1

  def build_attachment(attributes)
    attachments.build(
      attributes.merge(
        filename: attributes.fetch(:file).original_filename,
      ),
    )
  end
end
