window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}
;(function (Modules) {
  function GovspeakEditor (module) {
    this.module = module
  }

  GovspeakEditor.prototype.init = function () {
    this.initPreview()
  }

  GovspeakEditor.prototype.getCsrfToken = function () {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  GovspeakEditor.prototype.getRenderedGovspeak = function (body, callback) {
    const data = this.generateFormData(body)

    const request = new XMLHttpRequest()
    request.open('POST', 'preview', false)
    request.setRequestHeader('X-CSRF-Token', this.getCsrfToken())
    request.onreadystatechange = callback
    request.send(data)
  }

  GovspeakEditor.prototype.generateFormData = function (body) {
    const data = new FormData()
    data.append('body', body)
    data.append('authenticity_token', this.getCsrfToken())

    return data
  }

  GovspeakEditor.prototype.initPreview = function () {
    const previewToggle = this.module.querySelector(
      '.js-app-c-govspeak-editor__preview-button'
    )
    const preview = this.module.querySelector('.app-c-govspeak-editor__preview')
    const error = this.module.querySelector('.app-c-govspeak-editor__error')
    const textareaWrapper = this.module.querySelector(
      '.app-c-govspeak-editor__textarea'
    )
    const textarea = this.module.querySelector(
      previewToggle.getAttribute('data-content-target')
    )

    previewToggle.addEventListener(
      'click',
      function (e) {
        e.preventDefault()

        const previewMode = previewToggle.innerText === 'Preview'

        previewToggle.innerText = previewMode ? 'Back to edit' : 'Preview'
        textareaWrapper.classList.toggle(
          'app-c-govspeak-editor__textarea--hidden'
        )

        if (previewMode) {
          preview.classList.add('app-c-govspeak-editor__preview--show')
          this.getRenderedGovspeak(textarea.value, function (event) {
            const response = event.currentTarget

            if (response.readyState === 4) {
              if (response.status === 200) {
                preview.innerHTML = JSON.parse(response.responseText).preview_html
              }

              if (response.status === 403) {
                error.classList.add('app-c-govspeak-editor__error--show')
                preview.classList.remove('app-c-govspeak-editor__preview--show')
              }
            }
          })
        } else {
          preview.classList.remove('app-c-govspeak-editor__preview--show')
          error.classList.remove('app-c-govspeak-editor__error--show')
        }
      }.bind(this)
    )
  }

  Modules.GovspeakEditor = GovspeakEditor
})(window.GOVUK.Modules)
