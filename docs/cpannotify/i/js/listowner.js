
function clear_results() {
   document.getElementById('search_results').innerHTML = '';
}

Ajax.Responders.register({
  onCreate: function() {
    if($('busy') && Ajax.activeRequestCount>0) {
      Effect.Appear('busy',{duration:0.5,queue:'end'});
    }
  },
  onComplete: function() {
    if($('busy') && Ajax.activeRequestCount===0) {
      Effect.Fade('busy',{duration:0.5,queue:'end'});
    }
  }
});

function Unsubscribing(request, sub_id) {
	try {
          var sspan = document.getElementById(sub_id);
          sspan.className+=" unsubscribed";
	  Effect.Fade(sid,{duration:0.25});
	}
	catch(e) {
	  document.write(e.message + "<br/>");
        }
}

function Unsubscribed(request) {
	try {
	  var results = JSON.parse(request.responseText);
	  var sid   = results.list + '_' + results.email;
	  var sspan = document.getElementById(sid);
	  sspan.innerHTML = '<i>' + results.email + ' has been unsubscribed</i>';
	  sspan.className.replace(' unsubscribed', '');
	  Effect.Appear(sid,{duration:0.20,queue:'end'});
	} 
	catch(e) {
	    document.write(e.message + "<br/>");
	}	
}


function item_loaded(request) {
	for (var i=0; i<document.forms[0].elements.length; i++) {
		document.forms[0].elements[i].disabled = false;
	}

	document.getElementById('search_results').innerHTML = '';

	var results = JSON.parse(request.responseText);
//	Object.dpDump(results);

	try {

	  var rbox = document.getElementById('search_results');
	

	  for (var i in results) {
	    if (typeof results[i] == 'function') continue;
	    var listName = results[i][0];
	    var listSubscribers = results[i][1];
	    // Object.dpDump(listName);

	    new Insertion.Bottom('search_results', '<p><h3>' + listName + '</h3>');


	    for (var j in listSubscribers) {
	      var Subscriber = listSubscribers[j];
	      if (typeof Subscriber == 'function') continue;
	      // Object.dpDump("SUBS: " + Subscriber);

	      // should rewrite this to use the DOM to build the link etc... :-/
	      var sub_id = listName + '_' + Subscriber;
	      var sub_line = ''; 
	      sub_line = '<span id="' + sub_id
	      + '" class="subscriber"><a href="unsub?' + sub_id + '" onclick=" new Ajax.Request(  &#39;/api/unsubscribe?email=' 
	      + Subscriber + ';list=' + listName 
	      + '&#39;, { asynchronous: 1,onLoading: function(request){ Unsubscribing(request,sub_id) },onComplete: function(request){ Unsubscribed(request)} } ) ; return false">Unsubscribe</a>';

	      new Insertion.Bottom('search_results', sub_line + ' ' + Subscriber + '</span><br/>');
	    }
	    new Insertion.Bottom('search_results', '</table></p>');

	  }

	}
	catch(e) {
	    document.write(e.message + "<br/>");
	}	
	new Effect.Appear('search_results');
}

function item_loading() {
	for (var i=0; i<document.forms[0].elements.length; i++) {
		document.forms[0].elements[i].disabled = true;
	}
	//new Effect.Fade('search_results');
}
