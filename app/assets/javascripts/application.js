/* global pasteHtmlToGovspeak */
//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/lib
//= require govuk_publishing_components/components/button
//= require govuk_publishing_components/components/character-count
//= require govuk_publishing_components/components/details
//= require govuk_publishing_components/components/error-summary
//= require govuk_publishing_components/components/govspeak
//= require govuk_publishing_components/components/layout-header
//= require govuk_publishing_components/components/reorderable-list
//= require govuk_publishing_components/components/skip-link
//= require govuk_publishing_components/components/table

//= link vendor/jquery-1.11.0.min.js

//= link ajax_setup
//= link markdown_preview.js
//= require paste-html-to-govspeak

jQuery(function ($) {
  $('[data-module="js-paste-html-to-govspeak"]').each(function () {
    this.addEventListener('paste', pasteHtmlToGovspeak.pasteListener)
  })
})
