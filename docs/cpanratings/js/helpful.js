

CR.Helpful = {};

CR.Helpful.Vote = function(review_id, vote) {

  var status_span = YAHOO.util.Dom.get("thanks_" + review_id);
  if (!status_span)
    return;

   var callback = {
        success:function(o) {
          var review_id = o.argument.review_id;
          var status_span = YAHOO.util.Dom.get("thanks_" + review_id);
          var response =  eval( '(' + o.responseText + ')' );
          var status_text = '';
          if (response.error) {
            status_text = response.error;
          }
          else {
            status_text = 'Thanks! ' + response.message;
          }
          status_span.innerHTML = status_text;
        },
        failure:function(o) {
          var review_id = o.argument.review_id;
          var status_span = YAHOO.util.Dom.get("thanks_" + review_id);
          var status_text = o.statusText;
          if (o.status == -1)
            status_text = 'Timeout / Transaction aborted';
          status_span.innerHTML = 'Error: ' + status_text;
        },
        timeout: 15000,
        argument: { review_id: review_id }
   };

  status_span.innerHTML = '<img src="/images/progress.gif">';

  var transaction = YAHOO.util.Connect.asyncRequest('POST', '/api/helpful/vote', callback,
                                                    'auth_token=' + global_auth_token 
                                                    + '&review_id=' + review_id
                                                    + '&vote=' + vote); 

}
