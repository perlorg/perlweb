// Copyright 2006 Yahoo!

var YAHOO=function(){return{util:{},widget:{},example:{},namespace:function(sNameSpace){if(!sNameSpace||!sNameSpace.length){return null;}
var levels=sNameSpace.split(".");var currentNS=YAHOO;for(var i=(levels[0]=="YAHOO")?1:0;i<levels.length;++i){currentNS[levels[i]]=currentNS[levels[i]]||{};currentNS=currentNS[levels[i]];}
return currentNS;}};}();