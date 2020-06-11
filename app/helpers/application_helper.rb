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

  def nav_link_to(text, href)
    link_to(text, href)
  end

  def bootstrap_class_for(flash_type)
    case flash_type
    when :success
      "alert-success" # Green
    when :error
      "alert-danger" # Red
    when :alert
      "alert-warning" # Yellow
    when :notice
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
    "#{Plek.current.website_root}/#{manual.slug}"
  end

  def url_for_public_org(organisation_slug)
    "#{Plek.current.website_root}/government/organisations/#{organisation_slug}"
  end

  def content_preview_url(manual)
    "#{Plek.new.external_url_for('draft-origin')}/#{manual.slug}"
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
      if manual.version_type == :minor
        text += "<p>You are about to publish a <strong>minor edit</strong>.</p>"
      elsif manual.version_type == :major
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
