
if (!CR) {
    var CR = {};
}

$(document).ready(function() {

  var c = $.cookie('c')

  if (c) {
      var bc_u = c.match(/bc_u\/~([0-9]+)/);
      if (bc_u && bc_u[1] > 0) {
          c = bc_u[1];
          var login_link = $("#login_link");
          login_link.html("Logout");
          login_link.attr('href', '/logout');
      }
      else {
          c = 0;
      }
  }

  if (c) {
      $("div.review").each(
          function() {
              var attr = $(this).attr("data-user");
              if (attr == c) {
                  $(this).find(".helpfulq").html("&nbsp;");
              }
          });
  }


  $("span.helpful").click(function(ev) {
       var review = $(this).parents("div.review");
       var review_id = review.attr('data-review');

       var thanks_span = review.find("span.thanks");
       var vote = $(this).text().toLowerCase();

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
                          "vote": vote,
                          "review_id": review_id
                      },

                dataType: "json",
                type: "POST",
                statusCode: {
                    412: function() {
                        set_error("Login before voting");
                    }
                },
                error: function(msg) {
                    set_error("Whoops - something went wrong!<br>" + msg);
                }
             });
  });

  /* images/progress.gif */
});
