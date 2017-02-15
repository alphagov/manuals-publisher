require "gds_api/publishing_api_v2"

class DuplicateDraftDeleter
  def call
    duplicated_editions_not_in_publishing_api = duplicated_editions.reject { |data| in_publishing_api?(data[:content_id]) }
    content_ids = duplicated_editions_not_in_publishing_api.map { |data| data[:content_id] }
    editions_to_delete = SpecialistDocumentEdition.where(:document_id.in => content_ids)

    puts "The following #{editions_to_delete.count} editions are unknown to Publishing API and will be deleted:"
    editions_to_delete.each do |edition|
      puts [edition[:slug], edition[:document_id], edition[:state], edition[:created_at]].join(",")
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
    begin
      publishing_api.get_content(content_id).present?
    rescue GdsApi::HTTPNotFound
      false
    end
  end

  def duplicated_editions
    slug_hash = {}
    SpecialistDocumentEdition.all.each do |edition|
      slug_hash[edition.slug] ||= {}
      slug_hash[edition.slug][edition.document_id] ||= { state: edition.state, created_at: edition.created_at, editions: 0, content_id: edition.document_id, slug: edition.slug }
      slug_hash[edition.slug][edition.document_id][:editions] += 1
    end

    slug_hash.reject! { |_slug, documents| documents.size == 1 }
    slug_hash.values.map(&:values).flatten(1)
  end
end
