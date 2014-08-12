module ApplicationHelper
  # def facet_options(facet)
  #   finder_schema.options_for(facet)
  # end

  def state(document)
    state = document.publication_state

    if %w(published withdrawn).include?(state) && document.draft?
      state << " with new draft"
    end

    if document.draft?
      classes = "label label-primary"
    else
      classes = "label label-default"
    end

    content_tag(:span, state, class: classes).html_safe

  end

  def publication_task_state(task)
    formatted_time = nice_time_format(task.updated_at)

    case task.state
    when "queued", "processing"
      "This manual was sent for publishing at #{formatted_time}. It should be published shortly.".html_safe
    when "finished"
      "This manual was last published at #{formatted_time}".html_safe
    when "aborted"
      "This manual was sent for publishing at #{formatted_time}, but something went wrong. Our team has been notified.".html_safe
    end
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

  def govspeak(text)
    if text
      content_tag(:div, Govspeak::Document.new(text).to_sanitized_html.html_safe, class: "govspeak")
    end
  end

  def preview_path_for_cma_case(document)
    if document.persisted?
      preview_cma_case_path(document)
    else
      preview_new_cma_case_path
    end
  end

  def preview_path_for_aaib_report(document)
    if document.persisted?
      preview_aaib_report_path(document)
    else
      preview_new_aaib_report_path
    end
  end

  def preview_path_for_international_development_fund(document)
    if document.persisted?
      preview_international_development_fund_path(document)
    else
      preview_new_international_development_fund_path
    end
  end

  def preview_path_for_manual_document(manual, document)
    if document.persisted?
      preview_manual_document_path(manual, document)
    else
      preview_new_manual_document_path(manual)
    end
  end

  def url_for_public_manual(manual)
    "#{MANUAL_CONTENT_URL}/#{manual.slug}"
  end
end
