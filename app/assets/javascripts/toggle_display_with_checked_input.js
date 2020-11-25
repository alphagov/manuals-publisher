(function (window, $) {
  window.toggleDisplayWithCheckedInput = function (args) {
    var $input = args.$input
    var $element = args.$element
    var showElement = args.mode === 'show'

    var toggleOnChange = function () {
      if ($input.prop('checked')) {
        $element.toggle(showElement)
      } else {
        $element.toggle(!showElement)
      }
    }

    $input.change(toggleOnChange)
  }
})(window, $)
