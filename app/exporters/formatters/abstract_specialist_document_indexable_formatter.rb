require "formatters/abstract_indexable_formatter"

class AbstractSpecialistDocumentIndexableFormatter < AbstractIndexableFormatter

private
  def last_update
    publication_logs.any? ? publication_logs.last.published_at : entity.updated_at
  end

  def publication_logs
    PublicationLog.change_notes_for(entity.slug)
  end
end
