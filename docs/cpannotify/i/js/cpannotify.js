
function cancel_subscription() {
 /*   if (!document.getElementById('add_request') )
        return; */

    var removeElement = function() {
        var el = $('add_request');
        el.parentNode.removeChild(el);
    };

    var attributes = {
        height: {to: 0 },
        width:  {to: 200 },
        opacity: { to: 0.0 },
        fontSize: { from: 100, to: 0, unit: '%'}
    };
    var myAnim = new YAHOO.util.Anim('add_request', attributes, 0.3, YAHOO.util.Easing.easeIn);
    myAnim.onComplete.subscribe(removeElement);
    myAnim.animate();
}

function subscriptions_loaded(results) {
  try {
    var table = document.createElement('table');
    table.cellPadding = 2;
    table.cellSpacing = 0;
    table.border = 0;
    var tbody = document.createElement('TBODY');

    for (var s in results.subscriptions) {
      var sub = results.subscriptions[s];
      if (typeof sub == 'function') { continue; }

      var div = document.createElement('DIV');
      var tr = document.createElement('TR');

      var td = document.createElement('TD');
      var td2 = document.createElement('TD');
      var td3 = document.createElement('TD');
      td.appendChild( document.createTextNode(sub.type) );
      td2.appendChild(document.createTextNode(sub.name) );

      var unsubLink = document.createElement('A');
      unsubLink.setAttribute('href','/api/unsubscribe/' + sub.id);

      unsubLink.onclick = function() { unsubscribe(this.href); return false; };

      var linkText=document.createTextNode('Unsubscribe');
      unsubLink.appendChild(linkText);
      td3.appendChild(unsubLink);
      td3.id = 'unsub' + sub.id;

      tr.id = 'sub' + sub.id;
      // tr.setAttribute('class', 'sub' + sub.id);

      tr.appendChild(td);
      tr.appendChild(td2);
      tr.appendChild(td3);
      tbody.appendChild(tr);


      //alert(sub.name);
    }

    table.appendChild(tbody);
    table.id = 'subscriptionst';

    document.getElementById('subscriptions').innerHTML = '';
    document.getElementById('subscriptions').appendChild(table);
    stripe('subscriptionst', '#fff', '#edf3fe');
  }
  catch(e) {
    alert(e.message);
  }
}

function unsubscribed(request) {
  var results = JSON.parse(request.responseText);
  if (results.status == 'OK') {
    document.getElementById('unsub' + results.id).innerHTML = 'Unsubscribed';
    /*  cancel_subscription(); */
  }
  else {
    alert(request.responseText);
  }
}

var responseFailure = function(o) {
   alert('failure tld: ' + o.tld);
   $('subscriptions').innerHTML = o.responseText;
};


function unsubscribe(uri, id) {

  var responseSuccess = function(o) {
     unsubscribed(o);
  };

  var callback = {
     success : responseSuccess,
     failure : responseFailure
  };   

  YAHOO.util.Connect.asyncRequest('POST', uri, callback);
}

function confirm_subscription(name, type) {

  if (!type) { type = 'dist'; }

  var responseSuccess = function(o){
    cancel_subscription();
    load_subscriptions();
  };
  
  var callback = {
     success : responseSuccess,
     failure : responseFailure
  };

  YAHOO.util.Connect.asyncRequest('POST','/api/subscribe', callback, 'type=' + type + '&' + 'sub=' + name ); 

}

var load_subscriptions = function() {

  var responseSuccess = function(o){
    // $('subscriptions').innerHTML = o.responseText;
    var results = JSON.parse(o.responseText);
    subscriptions_loaded(results);
  };

  var callback = {
     success : responseSuccess,
     failure : responseFailure
  };

  YAHOO.util.Connect.asyncRequest('POST','/api/subscriptions?', callback);

};


YAHOO.util.Event.addListener(window, 'load', load_subscriptions);

