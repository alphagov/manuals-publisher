# encoding: UTF-8

module ApplicationHelper
  def state(document)
    state, classes = state_for_frontend(document)

    content_tag(:span, state, class: classes).html_safe

  end

  def state_for_frontend(document)
    state = document.publication_state

    if %w(published withdrawn).include?(state) && document.draft?
      state << " with new draft"
    end

    if document.draft?
      classes = "label label-primary"
    else
      classes = "label label-default"
    end
    [state, classes]
  end

  module_function :state_for_frontend

  def show_preview?(item)
    if item.respond_to?(:documents)
      item.draft? || item.documents.any?(&:draft?)
    else
      item.draft?
    end
  end

  def publication_task_state(task)
    zoned_time = time_with_local_zone(task.updated_at)
    formatted_time = nice_time_format(zoned_time)

    output =  case task.state
              when "queued", "processing"
                %Q(This manual was sent for publishing at #{formatted_time}.
                  It should be published shortly.)
              when "finished"
                %Q(This manual was last published at #{formatted_time}.)
              when "aborted"
                %Q(This manual was sent for publishing at #{formatted_time},
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

  def preview_path_for_manual_document(manual, document)
    if document.persisted?
      preview_manual_document_path(manual, document)
    else
      preview_new_manual_document_path(manual)
    end
  end

  def url_for_public_manual(manual)
    "#{Plek.current.website_root}/#{manual.slug}"
  end

  def url_for_public_org(organisation_slug)
    "#{Plek.current.website_root}/government/organisations/#{organisation_slug}"
  end

  def content_preview_url(document)
    "#{Plek.current.find("draft-origin")}/#{document.slug}"
  end

  def finders_sorted_by_title
    finders.sort_by {|_, value| value[:title] }
  end

end
