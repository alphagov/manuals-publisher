require "services"

class MarkedSectionDeleter
  def initialize(logger = STDOUT)
    @logger = logger
  end

  def execute(dry_run: true)
    dry_run = false if ENV["DO_IT"].present?

    @logger.puts "**** DRY RUN - NOTHING WILL BE DONE ****" if dry_run

    duplicated_editions = fetch_duplicated_editions

    @logger.puts "The following #{duplicated_editions.count} editions have been marked as XX for deletion:"
    duplicated_editions.each do |edition|
      @logger.puts [edition[:slug], edition[:section_uuid], edition[:state], edition[:created_at]].join(",")
    end

    known_editions, unknown_editions = duplicated_editions.partition { |edition| in_publishing_api?(edition[:content_id]) }

    @logger.puts "The following #{unknown_editions.count} are unknown to Publishing API and are safe to delete:"
    unknown_editions.each do |edition|
      @logger.puts [edition[:slug], edition[:content_id], edition[:state], edition[:created_at]].join(",")
      SectionEdition.all_for_section(edition[:content_id]).delete_all unless dry_run
    end

    @logger.puts "The following #{known_editions.count} are known to Publishing API and will be deleted after the draft is discarded:"
    known_editions.each do |edition|
      @logger.puts [edition[:slug], edition[:content_id], edition[:state], edition[:created_at]].join(",")
      unless dry_run
        publishing_api.discard_draft(edition[:content_id])
        SectionEdition.all_for_section(edition[:content_id]).delete_all
      end
    end
  end

  def publishing_api
    Services.publishing_api
  end

  def in_publishing_api?(content_id)
    publishing_api.get_content(content_id).present?
  rescue GdsApi::HTTPNotFound
    false
  end

  def marked_editions
    SectionEdition.where(title: /\Axx/i)
  end

  def fetch_duplicated_editions
    slug_hash = {}
    marked_editions.all.each do |edition|
      slug_hash[edition.slug] ||= {}
      slug_hash[edition.slug][edition.section_uuid] ||= { state: edition.state, created_at: edition.created_at, editions: 0, content_id: edition.section_uuid, slug: edition.slug }
      slug_hash[edition.slug][edition.section_uuid][:editions] += 1
    end

    slug_hash.values.map(&:values).flatten(1)
  end
end
