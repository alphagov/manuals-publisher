(function(window, $){
  window.toggleDisplayWithCheckedInput = function(args){
    var $input = args.$input,
      $element = args.$element,
      showElement = args.mode === 'show';

    var toggleOnChange = function(){
      console.log($input);
      console.log("args.$mode =" + args.$mode);
      if($input.prop("checked")) {
        console.log("checked - toggle: " + showElement);
        $element.toggle(showElement);
      }
      else {
        console.log("unchecked - toggle: " + !showElement);
        $element.toggle(!showElement);
      }
    }

    $input.change(toggleOnChange);
  };
})(window, $);
