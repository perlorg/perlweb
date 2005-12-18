

Ajax.Responders.register({
  onCreate: function() {
    if($('busy') && Ajax.activeRequestCount>0) {
      Effect.Appear('busy',{duration:0.1,queue:'end'});
    }
  },
  onComplete: function() {
    if($('busy') && Ajax.activeRequestCount===0) {
      Effect.Fade('busy',{duration:0.1,queue:'end'});
    }
  }
});


function cancel_subscription() {
  Effect.Fade('add_request', {duration:0.8});
}

function subscriptions_loading() {
  return true;
} 

function subscriptions_loaded(request) {
  try {

    var results = JSON.parse(request.responseText);

    var table = document.createElement('table');
    table.cellPadding = 2;
    table.cellSpacing = 0;
    table.border = 0;
    var tbody = document.createElement('TBODY');

    for (var s in results.subscriptions) {
      var sub = results.subscriptions[s];
      if (typeof sub == 'function') continue;

      var div = document.createElement('DIV');
      var tr = document.createElement('TR');

      var td = document.createElement('TD');
      var td2 = document.createElement('TD');
      var td3 = document.createElement('TD');
      td.appendChild( document.createTextNode(sub.type) );
      td2.appendChild(document.createTextNode(sub.name) );

      var unsubLink = document.createElement('A');
      unsubLink.setAttribute('href','unsubscribe/' + sub.id);
      unsubLink.setAttribute('onclick','unsubscribe("' + sub.id + '"); return false;');
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

function unsubscribed(id, request) {
  var results = JSON.parse(request.responseText);
  if (results.status = 'OK') {
    document.getElementById('unsub' + id).innerHTML = 'Unsubscribed';
    Effect.Puff('sub' + id, {duration:2.0});
  }
}

function unsubscribe(id) {
  new Ajax.Request(  '/api/unsubscribe?id=' + id, { asynchronous: 1,onComplete: function(request){  unsubscribed(id, request)} } );
}

function load_subscriptions() {
  //alert("loading them..");
  new Ajax.Request(  '/api/subscriptions', { asynchronous: 1,onLoading: function(request){ subscriptions_loading() },onComplete: function(request){  subscriptions_loaded(request)} } );
}

