var region_select;
var generalstation_select;
var plot_select;
var aggregation_select;
var quality_select;
var qualities = ["no", "physical", "step", "empirical"];
var qualitiesText = ["0: no","1: physical","2: physical + step","3: physical + step + empirical"];

var tasks = 0;

var incTask = function() {
	tasks++;	
	getID("status").innerHTML = "busy ("+tasks+")...";
}

var decTask = function() {
	tasks--;
	if(tasks===0) {
		getID("status").innerHTML = "ready";
	} else if(tasks<0){
		getID("status").innerHTML = "error";
	} else {
		getID("status").innerHTML = "busy ("+tasks+")...";
	}
}


$(document).ready(function(){
	incTask();
	region_select = $("#region_select");
	generalstation_select = $("#generalstation_select");
	plot_select = $("#plot_select");
	aggregation_select = $("#aggregation_select");
	quality_select = $("#quality_select");
	$.each(qualitiesText, function(i,text) {quality_select.append(new Option(text,i));});
	
	getID("region_select").onchange = updateGeneralStations;
	getID("generalstation_select").onchange = updatePlots;	
	getID("query_plot").onclick = runQueryPlot;
	
	updataRegions();
	decTask();
});

var updataRegions = function() {
	incTask();
	region_select.empty();
	$.get("/tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_select.append(new Option(row[1],row[0]));});
		//region_select.selectmenu( "refresh" );
		updateGeneralStations();
		decTask();		
	}).fail(function() {region_select.append(new Option("[error]","[error]"));decTask();});
}

var updateGeneralStations = function() {
	incTask();
	var regionName = region_select.val();
	generalstation_select.empty();	
	$.get("/tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {generalstation_select.append(new Option(row[1],row[0]));})
		//generalstation_select.selectmenu( "refresh" );
		updatePlots();
		decTask();	
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));decTask();});
}

var updatePlots = function() {
	incTask();
	var generalstationName = generalstation_select.val();
	plot_select.empty();	
	$.get("/tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_select.append(new Option(row[0],row[0]));})
		//plot_select.selectmenu( "refresh" );
		decTask();
	}).fail(function() {plot_select.append(new Option("[error]","[error]"));decTask();});
}

var runQueryPlot = function() {
	incTask();
	getID("result").innerHTML = "query...";
	var plotName = plot_select.val();
	$.get("/tsdb/sensor_list?plot="+plotName).done(function(data) {
		getID("result").innerHTML = "";
		sensors = splitData(data);
		$.each(sensors, function(i,row) {addDiagram(plotName,row[0],row[1],row[2]);})
		decTask();
	}).fail(function() {getID("result").innerHTML = "error";decTask();});
}

var addDiagram = function(plotName, sensorName, sensorDesc, sensorUnit) {
	incTask();
	var sensorResult = getID("result").appendChild(document.createElement("div"));
	var sensorResultTitle = sensorResult.appendChild(document.createElement("div"));
	sensorResultTitle.innerHTML += "query "+sensorName+"...";
	var aggregationName = aggregation_select.val();
	var qualityName = qualities[quality_select.val()];
	var interpolatedName = ""+getID("interpolated").checked;
	incTask();
	var image = new Image();
	sensorResult.appendChild(image);
	image.onload = function() {
		sensorResultTitle.innerHTML = sensorName+": "+sensorDesc+" - "+sensorUnit;
		decTask();
	}
	image.onerror = function() {	
		sensorResultTitle.innerHTML = sensorName+": no data";
		sensorResultTitle.style.color = "grey";
		sensorResult.removeChild(image);
		decTask();
	}
	image.src = "/tsdb/query_image?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName+"&quality="+qualityName+"&interpolated="+interpolatedName;
	decTask();	
}