require "services"

class DuplicateDraftDeleter
  def call
    duplicated_editions_not_in_publishing_api = duplicated_editions.reject { |data| in_publishing_api?(data[:content_id]) }
    content_ids = duplicated_editions_not_in_publishing_api.map { |data| data[:content_id] }
    editions_to_delete = SectionEdition.all_for_sections(*content_ids)

    logger.info "The following #{editions_to_delete.count} editions are unknown to Publishing API and will be deleted:"
    editions_to_delete.each do |edition|
      logger.info [edition.slug, edition.section_uuid, edition.state, edition.created_at].join(",")
      edition.delete
    end
  end

private

  def publishing_api
    Services.publishing_api
  end

  def in_publishing_api?(content_id)
    publishing_api.get_content(content_id).present?
  rescue GdsApi::HTTPNotFound
    false
  end

  def duplicated_editions
    slug_hash = {}
    SectionEdition.all.each do |edition|
      slug_hash[edition.slug] ||= {}
      slug_hash[edition.slug][edition.section_uuid] ||= { state: edition.state, created_at: edition.created_at, editions: 0, content_id: edition.section_uuid, slug: edition.slug }
      slug_hash[edition.slug][edition.section_uuid][:editions] += 1
    end

    slug_hash.reject! { |_slug, documents| documents.size == 1 }
    slug_hash.values.map(&:values).flatten(1)
  end
end
