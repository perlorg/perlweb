
function showYesNoCommunityResponse(uId,result,value) {
    var msgLayer = getElement("thanks" + uId);
    if ( result == "SUCCESS" ) {
	msgLayer.innerHTML = "Thanks! " + value;
    } else {
	showYesNoErrorResponse(uId,result,value);
    }
}

function getElement(id, d) {
    if (!d) d = document;
    if (d.getElementById) {
	return d.getElementById(id);
    }
    if (d.layers && d.layers[id]) {
	return d.layers[id];
    }
    if (d.all && d.all[id]) {
	return d.all[id];
    }
}

function showYesNoDefaultMessage(uId){
    document.write("<span class='tiny' style='color:#990000;margin-left:5px;' id='" + "thanks" + uId + "'></span>");
}

function restoreYesNoDefaultMessage(uId){
    var msgLayer = getElement("thanks" + uId);
    msgLayer.innerHTML = "";
}

function showYesButton(vUrl, uId){
    var yesVote = ' <a style="cursor:pointer; text-decoration: underline;" onclick="sendYesNoRating( \'' + vUrl + '&v=y\', \'' + uId + '\' ); return false;">Yes</a>';
    document.write(yesVote);
}

function showNoButton(vUrl, uId){
    var noVote = ' <a style="cursor:pointer; text-decoration: underline;" onclick="sendYesNoRating( \'' + vUrl + '&v=n\', \'' + uId + '\' ); return false">No</a>';
    document.write(noVote);
}

function sendYesNoRating(vUrl,uId){
    restoreYesNoDefaultMessage(uId);
    var voteLayer = getElement('YesNoVotingFrame');
    voteLayer.src = vUrl;
}

function showYesNoResponse(uId,result,value) {
    var msgLayer = getElement("thanks" + uId);
    if ( result == "SUCCESS" ) {
	msgLayer.innerHTML = "Thank you for your feedback.";
    } else {
	showYesNoErrorResponse(uId,result,value);
    }
}

function showYesNoErrorResponse(uId,result,value) {
    var msgLayer = getElement("thanks" + uId);
    if ( result == "BADVOTE" ) {
	msgLayer.innerHTML = "There was a problem with your request.";
    }
    else if ( result == "UNRECOGNIZED" ) {
	msgLayer.innerHTML = "You must be logged in to vote.";
    }
    else if ( result == "SERVICE-FAILURE" ) {
	msgLayer.innerHTML = "There was an error processing your request. Please try again later.";
    }
    else if ( result == "ILLEGAL" ) {
	msgLayer.innerHTML = "You are not allowed to vote on your own review.";
    }
    else {
	msgLayer.innerHTML = result;
    }
}

