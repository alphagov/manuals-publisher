require "gds_api/content_store"

class ManualAndSectionsRedirecter
  def initialize(args)
    @publishing_api ||= SpecialistPublisherWiring.get(:publishing_api)
    @content_store ||= GdsApi::ContentStore.new(Plek.current.find("content-store"))
    @logger = args[:logger] || STDOUT
    @base_path = args[:base_path]
    @destination = args[:destination]
  end

  def redirect
    run(redirect: true)
  end

  def report
    run(redirect: false)
  end

private

  attr_reader :base_path, :content_store, :destination, :logger, :publishing_api

  def run(redirect:)
    manual_response = content_store.content_item(base_path)

    raise "Could not retrieve manual with base_path: #{base_path} from content store" unless manual_response.code == 200
    manual = manual_response.to_hash.deep_symbolize_keys

    manual_slug = base_path[1..-1]
    manual_record = ManualRecord.where(slug: manual_slug).first

    if manual_record
      logger.puts "Redirecting #{base_path} to #{destination}"

      if redirect
        # Redirect the manual
        PublishingAPIRedirecter.new(
          publishing_api: publishing_api,
          entity: manual_record,
          redirect_to_location: destination
        ).call

        if manual[:links]
          manual[:links][:sections].each do |section|
            section_slug = section["base_path"][1..-1]
            section_edition = SpecialistDocumentEdition.where(slug: section_slug).last

            if section_edition
              logger.puts "Redirecting /#{section_edition.slug} to #{destination}"

              # Redirect each manual section
              PublishingAPIRedirecter.new(
                publishing_api: publishing_api,
                entity: section_edition,
                redirect_to_location: destination
              ).call
            end
          end
        end
      end
    end
  end
end
