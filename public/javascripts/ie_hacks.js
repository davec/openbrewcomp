/* [TODO] Is all this tag name checking really required? It shouldn't be, but this is IE we're dealing with here. */
navigationStartList = function()
{
  if (document.all && document.getElementById)
  {
    body_width = document.body.clientWidth;
    $('navigation').immediateDescendants().each(function(e) {
      if (e.tagName == 'LI')
      {
        if (e.previous() == undefined)
        {
          e.addClassName('firstlink');
        }
        e.onmouseover = function() { e.addClassName('over'); }
        e.onmouseout = function() { e.removeClassName('over'); }
        e.immediateDescendants().each(function(e) {
          if (e.tagName == 'UL')
          {
            e.style.width = body_width;
            e.immediateDescendants().each(function(e) {
              if (e.tagName == 'LI')
              {
                if (e.previous() == undefined)
                {
                  e.addClassName('firstlink');
                }
              }
            })
          }
        });
      }
    });

    if ($('reports-menu'))
    {
      $('reports-menu').immediateDescendants().each(function(e) {
        if (e.tagName == 'LI')
        {
          e.onmouseover = function() { this.className += " over"; }
          e.onmouseout = function() { this.className = this.className.replace(" over", ""); }
        }
      });
    }
  }
}
Event.observe(window, 'load', navigationStartList);
