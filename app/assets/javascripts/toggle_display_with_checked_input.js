(function(window, $){
  window.toggleDisplayWithCheckedInput = function(args){
    var $input = args.$input,
      $element = args.$element,
      showElement = args.mode === 'show';

    var toggleOnChange = function(){
      if($input.prop("checked")) {
        $element.toggle(showElement);
      } else {
        $element.toggle(!showElement);
      }
    }

    $input.change(toggleOnChange);
  };
})(window, $);
