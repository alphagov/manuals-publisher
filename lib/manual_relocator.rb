class ManualRelocator
  def self.move(from_slug, to_slug)
    redirect_and_remove(to_slug)
    reslug(from_slug, to_slug)
  end

private

  def self.redirect_and_remove(manual_slug)
    manual_records = ManualRecord.where(slug: manual_slug)
    raise "No manual found for slug '#{manual_slug}'" unless manual_records.any?

    puts "Found #{manual_records.count} manuals for slug '#{manual_slug}'"

    manual_records.each do |manual_record|
      if manual_record.editions.any?
        # Redirect all sections of the manual we're going to remove
        # to prevent dead bookmarked URLs.
        document_ids = manual_record.editions.flat_map(&:document_ids).uniq

        document_ids.each do |document_id|
          editions = SpecialistDocumentEdition.where(document_id: document_id)
          edition = editions.last

          begin
            puts "Redirecting content item '/#{edition.slug}' to '/#{manual_slug}'"
            publishing_api.unpublish(edition.document_id,
                                     type: "redirect",
                                     alternative_path: "/#{manual_slug}",
                                     discard_drafts: true)
          rescue GdsApi::HTTPNotFound
            puts "Content item with content_id #{document_id} not present in the publishing API"
          end

          # Destroy all the editons of this manual as it's going away
          editions.map(&:destroy)
        end
      end

      puts "Destroying old PublicationLogs for #{manual_record.slug}"
      PublicationLog.change_notes_for(manual_record.slug).each { |log| log.destroy }

      # Destroy the manual record
      puts "Destroying manual #{manual_record._id}"
      manual_record.destroy
    end
  end

  def self.reslug(old_slug, new_slug)
    hca_manual_record = ManualRecord.find_by(slug: old_slug)

    # Reslug the manual sections
    hca_document_ids = hca_manual_record.editions.flat_map(&:document_ids).uniq
    hca_document_ids.each do |document_id|
      sections = SpecialistDocumentEdition.where(document_id: document_id)
      sections.each do |section|
        reslug_msg = "Reslugging section '#{section.slug}'"
        section.slug.gsub!(old_slug, new_slug)
        puts "#{reslug_msg} as '#{section.slug}'"
        section.save!
      end
    end

    # Reslug the manual
    reslug_msg = "Reslugging manual '#{hca_manual_record.slug}'"
    new_slug = hca_manual_record.slug.gsub(old_slug, new_slug)
    puts "#{reslug_msg} as '#{new_slug}'"

    hca_manual_record.set(:slug, new_slug)

    # Reslug the existing publication logs
    puts "Reslugging publication logs for #{old_slug} to #{new_slug}"
    PublicationLog.change_notes_for(old_slug).each do |publication_log|
      publication_log.set(:slug, publication_log.slug.gsub(old_slug, new_slug))
    end
    puts PublicationLog.change_notes_for(new_slug).inspect

    # Clean up manual sections belonging to the temporary manual path
    hca_document_ids = hca_manual_record.editions.flat_map(&:document_ids).uniq
    hca_document_ids.each do |document_id|
      puts "Redirecting #{document_id} to '/#{new_slug}'"
      publishing_api.unpublish(document_id,
                               type: "redirect",
                               alternative_path: "/#{new_slug}",
                               discard_drafts: true)
    end

    # Clean up the drafted manual in the Publishing API
    puts "Redirecting #{hca_manual_record.manual_id} to '/#{new_slug}'"
    publishing_api.unpublish(hca_manual_record.manual_id,
                             type: "redirect",
                             alternative_path: "/#{new_slug}",
                             discard_drafts: true)
  end

  def self.publishing_api
    ManualsPublisherWiring.get(:publishing_api_v2)
  end
end
