
if (!CR) {
    var CR = {};
}

$(document).ready(function() {

  $("span.helpful").click(function(ev) {
       var review = $(this).parents("div.review");
       var review_id = review.attr('data-review');

       var thanks_span = review.find("span.thanks");

       // $("#reviews").find("span.thanks.done").not(thanks_span).fadeOut();

       thanks_span.removeClass("error");
       thanks_span.html("Saving ...");
       thanks_span.show();

       var set_error = function (err) {
           thanks_span.html(err);
           thanks_span.addClass("error");
           thanks_span.addClass("done");
       };

       $.ajax({ url: "/api/helpful/vote",
                success: function(data) {
                    if (data.error) {
                        thanks_span.html( data.error );
                        thanks_span.addClass("error");
                        return;
                    }
                    thanks_span.addClass("done");
                    thanks_span.html(data.message);
                },
                data: { "auth_token": global_auth_token,
                          "vote": "yes",
                          "review_id": review_id
                      },

                dataType: "json",
                type: "POST",
                statusCode: {
                    412: function() {
                        set_error("Auth failure");
                    }
                },
                error: function(msg) {
                    set_error("Whoops - something went wrong!<br>" + msg);
                }
             });
  });

  /* images/progress.gif */
});
