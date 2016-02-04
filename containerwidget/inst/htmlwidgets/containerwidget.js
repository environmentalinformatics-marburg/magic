HTMLWidgets.widget({

  name: 'containerwidget',

  type: 'output',

  initialize: function(el, width, height) {

    return {};

  },

  renderValue: function(el, x, instance) {

    if(x.css!==null) {
      addcss(x.css);
    }

    if(x.html!==null) {
      el.innerHTML = x.html;
    }

    if(x.javascript!==null) {
      eval(x.javascript);
    }

  },

  resize: function(el, width, height, instance) {
    //console.log("resize "+width+" "+height);
  }

});

function addcss(css){ // source: http://stackoverflow.com/questions/3922139/add-css-to-head-with-javascript
    var head = document.getElementsByTagName('head')[0];
    var s = document.createElement('style');
    s.setAttribute('type', 'text/css');
    if (s.styleSheet) {   // IE
        s.styleSheet.cssText = css;
    } else {                // the world
        s.appendChild(document.createTextNode(css));
    }
    head.appendChild(s);
}
