var region_select;
var generalstation_select;
var sensor_select;
var time_select;
var quality_select;
var scale_factor_select;
var qualities = ["no", "physical", "step", "empirical"];
var qualitiesText = ["0: no","1: physical","2: physical + step","3: physical + step + empirical"];
var timeText = ["[all]","2008","2009","2010","2011","2012","2013","2014","2015"];
var scaleFactors = [1,2,3,4];
var testingImage = "";
var scale_factor = 2;

var sensors;

var tasks = 0;

$(document).ready(function(){
	incTask();
	region_select = $("#region_select");
	generalstation_select = $("#generalstation_select");
	sensor_select = $("#sensor_select");
	time_select = $("#time_select");
	quality_select = $("#quality_select");
	scale_factor_select = $("#scale_factor_select");
	$.each(qualitiesText, function(i,text) {quality_select.append(new Option(text,i));});
	quality_select.val(2);
	$.each(timeText, function(i,text) {time_select.append(new Option(text,i));});
	
	$.each(scaleFactors, function(i,factor) {scale_factor_select.append(new Option("x"+factor,factor));});
	scale_factor_select.val(2);
	
	getID("region_select").onchange = updateGeneralStations;
	getID("generalstation_select").onchange = updateSensors;	
	getID("sensor_select").onchange = updateSensor;
	getID("query_sensor").onclick = runQuerySensor;
	getID("scale_factor_select").onchange = updateScaleFactor;
	
	updataRegions();
	decTask();
});

var incTask = function() {
	runDisabled(true);
	tasks++;	
	getID("status").innerHTML = "busy ("+tasks+")...";
}

var decTask = function() {
	tasks--;
	if(tasks===0) {
		getID("status").innerHTML = "ready";
		runDisabled(false);
	} else if(tasks<0){
		getID("status").innerHTML = "error";
	} else {
		getID("status").innerHTML = "busy ("+tasks+")...";
	}
}

function runDisabled(disabled) {
	$(".blockable").prop( "disabled",disabled);
}

var updataRegions = function() {
	incTask();
	region_select.empty();
	$.get("../tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_select.append(new Option(row[1],row[0]));});
		updateGeneralStations();
	    decTask();
	}).fail(function() {region_select.append(new Option("[error]","[error]"));decTask();});
}

var updateGeneralStations = function() {
	incTask();
	var regionName = region_select.val();
	generalstation_select.empty();	
	$.get("../tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		generalstation_select.append(new Option("[all]","[all]"));
		$.each(rows, function(i,row) {generalstation_select.append(new Option(row[1],row[0]));})
		updateSensors();
		decTask();		
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));decTask();});
}

var updateSensors = function() {
	incTask();
	
	var prev = "unknown";
	if(sensor_select.val()!=null) {
		prev = sensors[sensor_select.val()][0];
	}
	
	var queryText = "";
	var generalStationName = generalstation_select.val();	
	if(generalStationName==="[all]") {
		queryText = "region="+region_select.val();
	} else {
		queryText = "general_station="+generalStationName;
	}	
	sensor_select.empty();	
	$.get("../tsdb/sensor_list?"+queryText).done(function(data) {
		var pre = -1;
		var rows = splitData(data);
		sensors = rows
		//$.each(sensors, function(i,row) {document.getElementById("sensor_select").add(new Option(row[0],i));})
		$.each(rows, function(i,row) {
			sensor_select.append(new Option(row[0],i));
			if(row[0]===prev) {
				pre = i;
			}
			if(pre<0&&row[0]==="Ta_200") {
				pre = i;
			}
		})
		
		if(pre>0) {
			sensor_select.val(pre);
		}
		
		updateSensor();		
		decTask();
	}).fail(function() {sensor_select.append(new Option("[error]","[error]"));decTask();});
}

var updateSensor = function() {
	incTask();
	var row = sensors[sensor_select.val()];
	getID("sensor_description").innerHTML = row[1];
	getID("sensor_unit").innerHTML = row[2];
	decTask();
}

 function updateScaleFactor() {
	 incTask();
	 var factor = scale_factor_select.val();
	 if(factor>0 && factor<10) {
		 scale_factor = factor;
		 $(".heatmap img").each(function(i,img) {
			img.width = img.naturalWidth*scale_factor;
			img.height = img.naturalHeight*scale_factor;
		});
		 
	 }
	 decTask();
 }

var runQuerySensor = function() {
	incTask();
	getID("result").innerHTML = "query...";
	var sensorName = sensors[sensor_select.val()][0];
	generalStationName = generalstation_select.val();	
	var queryText = "";
	if(generalStationName==="[all]") {
		queryText = "region="+region_select.val();
	} else {
		queryText = "generalstation="+generalStationName;
	}
	$.get("../tsdb/plot_list?"+queryText).done(function(data) {
		getID("result").innerHTML = "";	
		var rows = splitData(data);
		addValueScale(sensorName);
		$.each(rows, function(i,row) {addDiagram(row[0],sensorName);})
		decTask();		
	}).fail(function() {getID("result").innerHTML = "error";decTask();})
}

var addValueScale = function(sensorName) {
	incTask();
	var plotResult = getID("result").appendChild(document.createElement("div"));
	var plotResultTitle = plotResult.appendChild(document.createElement("div"));
	plotResultTitle.innerHTML += "query scale...";

	var image = new Image();

	plotResult.appendChild(image);
	image.onload = function() {
		plotResultTitle.innerHTML = "";
		decTask();
	}
	image.onerror = function() {	
		plotResult.innerHTML = "error in scale";
		decTask();
	}
	image.src = "../tsdb/heatmap_scale?sensor="+sensorName;	
}

var addDiagram = function(plotName, sensorName) {
	incTask();
	var plotResult = getID("result").appendChild(document.createElement("div"));
	plotResult.className = "heatmap";
	var plotResultTitle = plotResult.appendChild(document.createElement("div"));
	plotResultTitle.innerHTML += "query "+plotName+"...";
	var qualityName = qualities[quality_select.val()];
	var interpolatedName = ""+getID("interpolated").checked;
	var timeParameter = "";
	var timeName = timeText[time_select.val()];
	if(timeName!="[all]") {
		timeParameter = "&year="+timeName;
	}
	var image = new Image();
	//var need_to_scale = true;
	plotResult.appendChild(image);
	image.onload = function() {
		plotResultTitle.innerHTML = plotName;
		decTask();
		image.width = image.naturalWidth*scale_factor;
		image.height = image.naturalHeight*scale_factor;
		//testingImage = image;
		/*if(need_to_scale) {
			need_to_scale = false;
			image.width = image.width*2;			
			image.height = (24+12)*2;
			//image.width = image.width*4;			
			//image.height = 24*4;
			//image.width = image.width*3;			
			//image.height = 24*3;//image.height = image.height*3;
		}*/
	}
	image.onerror = function() {	
		/*plotResultTitle.innerHTML = plotName+": no data";
		plotResultTitle.style.color = "grey";
		plotResult.removeChild(image);*/
		plotResult.innerHTML = "";
		decTask();
	}
	image.src = "../tsdb/query_heatmap?plot="+plotName+"&sensor="+sensorName+"&quality="+qualityName+"&interpolated="+interpolatedName+timeParameter;	
}
