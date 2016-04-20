require "gds_api/publishing_api_v2"

class DuplicateDraftDeleter
  def call
    duplicated_editions_not_in_publishing_api = duplicated_editions.reject {|data| in_publishing_api?(data[:content_id]) }

    puts "The following #{duplicated_editions_not_in_publishing_api.count} unpublished drafts are being deleted:"
    duplicated_editions_not_in_publishing_api.each do |data|
      puts [data[:slug], data[:content_id], data[:state], data[:created_at]].join(",")
      edition = SpecialistDocumentEdition.where(document_id: data[:content_id]).first
      edition.delete
    end
  end

private

  def publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example"
    )
  end

  def in_publishing_api?(content_id)
    publishing_api.get_content(content_id).present?
  end

  def duplicated_editions
    slug_hash = {}
    SpecialistDocumentEdition.all.each do |edition|
      slug_hash[edition.slug] ||= {}
      slug_hash[edition.slug][edition.document_id] ||= {state: edition.state, created_at: edition.created_at, editions: 0, content_id: edition.document_id, slug: edition.slug}
      slug_hash[edition.slug][edition.document_id][:editions] += 1
    end

    slug_hash.reject! { |_slug, documents| documents.size == 1 }
    slug_hash.values.map(&:values).flatten(1)
  end
end
