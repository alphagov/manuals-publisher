class AttachmentReporting
  POST_PUBLICATION_STATES = %w[published archived].freeze

  def initialize(first_period_start_date, last_time_period_days, attachment_file_extension)
    @first_period_start_date = first_period_start_date
    @last_time_period_days = last_time_period_days
    @attachment_file_extension = attachment_file_extension
  end

  def create_organisation_attachment_count_hash
    manuals = Manual.all(User.gds_editor).to_a
    unique_owning_organisation_slugs = manuals.map(&:organisation_slug).uniq

    # Hash of organisation names mapped to three-element arrays of counts of PDFs, one count for each time period
    organisation_published_pdfs_counts_hash = unique_owning_organisation_slugs.index_with { [0, 0, 0] }

    manuals.each do |manual|
      next unless manual.has_ever_been_published?

      unique_pdf_attachment_file_ids_for_manual = Set.new

      manual.sections.each do |section|
        section.all_editions.sort_by(&:version_number).each do |section_edition|
          next if section_edition_never_published?(section_edition)

          section_edition.attachments.each do |attachment|
            next if unique_pdf_attachment_file_ids_for_manual.include? attachment.file_id
            next unless report_attachment_extension_matches?(attachment.filename)

            organisation_published_pdfs_counts_hash[manual.organisation_slug][0] += 1

            if section_published_after_date?(section_edition, @first_period_start_date)
              organisation_published_pdfs_counts_hash[manual.organisation_slug][1] += 1
            end

            if section_published_after_date?(section_edition, last_time_period_start_date)
              organisation_published_pdfs_counts_hash[manual.organisation_slug][2] += 1
            end

            unique_pdf_attachment_file_ids_for_manual << attachment.file_id
          end
        end
      end
    end

    titleize_keys(organisation_published_pdfs_counts_hash)
  end

private

  def titleize_keys(hash)
    hash.each_key.with_object({}) do |key, out|
      out[key.titleize] = hash[key]
    end
  end

  def report_attachment_extension_matches?(filename)
    /.*\.#{@attachment_file_extension}/ =~ filename
  end

  def last_time_period_start_date
    @last_time_period_start_date ||= @last_time_period_days.days.ago
  end

  def section_published_after_date?(section_edition, date)
    (section_edition.exported_at || section_edition.updated_at) >= date
  end

  def section_edition_never_published?(section_edition)
    !POST_PUBLICATION_STATES.include?(section_edition.state)
  end
end
