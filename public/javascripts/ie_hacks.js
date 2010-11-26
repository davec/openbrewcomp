navigationStartList = function() {
  if (document.all && document.getElementById) {
    var body_width = document.body.clientWidth;

    $('navigation').childElements().each(function(e,i) {
      if (i === 0) e.addClassName('firstlink');

      e.onmouseover = function() { e.addClassName('over'); };
      e.onmouseout = function() { e.removeClassName('over'); };
      e.childElements().each(function(e) {
        if (e.tagName == 'UL') {
          e.style.width = body_width;
          e.childElements().first().addClassName('firstlink');
        }
      });
    });

    if ($('reports-menu')) {
      $('reports-menu').childElements().each(function(e) {
        e.onmouseover = function() { e.addClassName('over'); };
        e.onmouseout = function() { e.removeClassName('over'); };
      });
    }
  }
}
Event.observe(window, 'load', navigationStartList);
