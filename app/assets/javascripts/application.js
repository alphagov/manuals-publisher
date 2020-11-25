//= require vendor/jquery-1.11.0.min
//= require vendor/jquery-ui.min.js

//= require govuk_toolkit
//= require ajax_setup
//= require length_counter
//= require markdown_preview
//= require toggle_display_with_checked_input

function initPrimaryLinks () {
  GOVUK.primaryLinks.init('.primary-item')
}
$(initPrimaryLinks)
$(window).on('displayPreviewDone', initPrimaryLinks)

jQuery(function ($) {
  $('.js-length-counter').each(function () {
    new GOVUK.LengthCounter({ $el: $(this) }) // eslint-disable-line no-new
  })

  $('.reorderable-document-list').sortable()
})
