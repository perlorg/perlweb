
$(document).ready(function(){

        // // External link, add image + make open in new page
        // $('.ext').filter(function(obj) {
        //     this.target="_blank";
        //     return 1;
        // }).after(' <img src="/i/external.v1.png" alt="external link"/>');
        //
        // $("a:not(img)").filter(function(obj) {
        //     this.target="_blank";
        //     return 1;
        // }).after(' <img src="/i/external.v1.png" alt="external link"/>');
        //

        var link_filter = function() {
            // If it's an image, do NOT show icon
            if($(this).find('img').length)
                return 0;
            // some widgets get an image via CSS
            if( $(this).html().length == 0) {
                return 0;
            }
            // If it's external, ok
            if(this.hostname && this.hostname !== location.hostname) {
                this.target="_blank";
                $(this).after('<img class="extlink" src="/i/external.v1.png" alt="external link"/>');
            }
            return 0;
        };

        $('#content a').filter(link_filter);
        $('#footer a').filter(link_filter);

        $('.round').corner("7px top");
		$('.module').corner("10px top");
		//$('.button').corner("7px");
		// Any divs that should get hidden onload should have this as a class
		$('.hidediv').toggle();

		(new Image()).src = "//www.mapper.ntppool.org/none";
});

