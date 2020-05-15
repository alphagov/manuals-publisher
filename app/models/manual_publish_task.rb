require "state_machine"

class ManualPublishTask
  include Mongoid::Document
  include Mongoid::Timestamps

  field :manual_id, type: String
  field :version_number, type: Integer
  field :state, type: String
  field :error, type: String

  scope :for_manual,
        lambda { |manual|
          all
            .where(manual_id: manual.id)
            .order_by(%i[version_number desc], %i[updated_at desc])
        }

  state_machine initial: :queued do
    event :start! do
      transition queued: :processing
    end

    event :finish! do
      transition processing: :finished
    end

    event :abort! do
      transition processing: :aborted
    end
  end
end
