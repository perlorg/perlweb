
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

  $("#show_unhelpful").click(function(ev) {
       var unhelpful_div = $(this);
       $.ajax({ url: "/api/review/get",
                success: function(data) {
                    if (data.html) {
                        unhelpful_div.parents("#reviews").append( data.html );
                        unhelpful_div.hide();
                    }
                },
                data: { "auth_token": global_auth_token,
                        "dist": $(this).attr('data-dist'),
                        "unhelpful": 1,
                        "html": 1
                      },
                dataType: "json",
                type: "GET"
      });
  });

  /* images/progress.gif */
});
