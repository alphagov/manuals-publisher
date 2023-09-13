module ApplicationHelper
  def state(manual)
    state = manual.publication_state

    if %w[published withdrawn].include?(state) && manual.draft?
      state << " with new draft"
    end

    classes = if manual.draft?
                "label label-primary"
              else
                "label label-default"
              end

    tag.span(state, class: classes).html_safe
  end

  def state_label(manual)
    state_text = manual.publication_state

    if state_text == "published" && manual.draft?
      state_text << " with new draft"
    end

    classes = "govuk-tag govuk-tag--s"
    classes << if manual.draft?
                 " govuk-tag--blue"
               elsif manual.published?
                 " govuk-tag--green"
               else
                 " govuk-tag--grey"
               end

    tag.span(state_text, class: classes).html_safe
  end

  def manual_metadata_rows(manual)
    rows = [
      {
        key: "Status",
        value: state_label(manual),
      },
    ]

    if current_user_is_gds_editor?
      rows << {
        key: "From",
        value: link_to(manual.organisation_slug, url_for_public_org(manual.organisation_slug)),
      }
    end

    if manual.originally_published_at.present?
      rows << {
        key: "Originally published",
        value: nice_time_format(manual.originally_published_at),
      }
    end

    if manual.publish_tasks.any?
      value = publication_task_state(manual.publish_tasks.first)
      if manual.use_originally_published_at_for_public_timestamp?
        value += safe_join([tag.br, "This will be used as the public updated at timestamp on GOV.UK."])
      end
      rows << {
        key: "Last published",
        value:,
      }
    end
    rows
  end

  def manual_front_page_rows(manual)
    rows = [
      {
        key: "Slug",
        value: manual.slug,
      },
      {
        key: "Title",
        value: sanitize(manual.title),
      },
      {
        key: "Summary",
        value: sanitize(manual.summary),
      },
    ]

    if manual.body.present?
      rows << {
        key: "Body",
        value: simple_format(truncate(manual.body, length: 500, class: "govuk-!-margin-top-0")),
      }
    end

    rows
  end

  def manual_sidebar_action_items(manual, slug_unique)
    items = []

    if allow_publish?(manual, slug_unique)
      items << render("govuk_publishing_components/components/button", {
        text: "Publish",
        href: confirm_publish_manual_path(manual),
      })
    end

    unless manual.has_ever_been_published?
      items << render("govuk_publishing_components/components/button", {
        text: "Discard",
        destructive: true,
      })
    end

    items
  end

  def manual_section_rows(manual)
    manual.sections.map do |section|
      row = {}

      row[:key] = if section.draft?
                    draft_tag = tag.span("DRAFT", class: "govuk-tag govuk-tag--s govuk-tag--blue")
                    title_span = tag.span(section.title, class: "govuk-!-static-margin-2")
                    draft_tag << title_span
                  else
                    tag.span(section.title)
                  end
      row[:value] = last_updated_text(section)
      row[:actions] = [{
        label: "View",
        href: manual_section_path(manual, section),
      }]
      row
    end
  end

  def show_preview?(item)
    if item.respond_to?(:sections)
      item.draft? || item.sections.any?(&:draft?)
    else
      item.draft?
    end
  end

  def publication_task_state(task)
    zoned_time = time_with_local_zone(task.updated_at)
    formatted_time = nice_time_format(zoned_time)

    output =  case task.state
              when "queued", "processing"
                %(This manual was sent for publishing at #{formatted_time}.
                  It should be published shortly.)
              when "finished"
                %(This manual was last published at #{formatted_time}.)
              when "aborted"
                %(This manual was sent for publishing at #{formatted_time},
                  but something went wrong. Our team has been notified.)
              end

    output.html_safe
  end

  def bootstrap_class_for(flash_type)
    case flash_type
    when "success"
      "alert-success" # Green
    when "error"
      "alert-danger" # Red
    when "alert"
      "alert-warning" # Yellow
    when "notice"
      "alert-info" # Blue
    else
      flash_type.to_s
    end
  end

  def preview_path_for_manual(manual)
    if manual.persisted?
      preview_manual_path(manual)
    else
      preview_new_manual_path
    end
  end

  def preview_path_for_section(manual, section)
    if section.persisted?
      preview_manual_section_path(manual, section)
    else
      preview_new_section_path(manual)
    end
  end

  def url_for_public_manual(manual)
    "#{Plek.website_root}/#{manual.slug}"
  end

  def url_for_public_org(organisation_slug)
    "#{Plek.website_root}/government/organisations/#{organisation_slug}"
  end

  def content_preview_url(manual)
    "#{Plek.external_url_for('draft-origin')}/#{manual.slug}"
  end

  def allow_publish?(manual, slug_unique)
    manual.draft? && manual.sections.any? && current_user_can_publish? && slug_unique
  end

  def last_updated_text(section)
    text = "Updated #{time_ago_in_words(section.updated_at)} ago"

    if section.draft? && section.last_updated_by
      text << " by #{section.last_updated_by}"
    end

    text
  end

  def publish_text(manual, slug_unique)
    if manual.state == "published"
      text = "<p>There are no changes to publish.</p>"
    elsif manual.state == "withdrawn"
      text = "<p>The manual is withdrawn. You need to create a new draft before it can be published.</p>"
    elsif !current_user_can_publish?
      text = "<p>You don't have permission to publish this manual.</p>"
    elsif !slug_unique
      text = "<p>This manual has a duplicate slug and can't be published.</p>"
    else
      text = ""
      case manual.version_type
      when :minor
        text += "<p>You are about to publish a <strong>minor edit</strong>.</p>"
      when :major
        text += "<p><strong>You are about to publish a major edit with public change notes.</strong></p>"
      end
      text += if manual.use_originally_published_at_for_public_timestamp? && manual.originally_published_at.present?
                "<p>The updated timestamp on GOV.UK will be set to the first publication date.</p>"
              elsif manual.version_type == :minor
                "<p>The updated timestamp on GOV.UK will not change.</p>"
              else
                "<p>The updated timestamp on GOV.UK will be set to the time you press the publish button.</p>"
              end
    end

    (text || "").html_safe
  end
end
