var region_select;
var generalstation_select;
var plot_select;
var aggregation_select;

$(document).ready(function(){
	region_select = $("#region_select");
	generalstation_select = $("#generalstation_select");
	plot_select = $("#plot_select");
	aggregation_select = $("#aggregation_select");
	
	getID("region_select").onchange = updateGeneralStations;
	getID("generalstation_select").onchange = updatePlots;	
	getID("query_plot").onclick = runQueryPlot;
	
	updataRegions();
});

var updataRegions = function() {
	region_select.empty();
	$.get("/tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_select.append(new Option(row[1],row[0]));});
		//region_select.selectmenu( "refresh" );
		updateGeneralStations();		
	}).fail(function() {region_select.append(new Option("[error]","[error]"));});
}

var updateGeneralStations = function() {
	var regionName = region_select.val();
	generalstation_select.empty();	
	$.get("/tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {generalstation_select.append(new Option(row[1],row[0]));})
		//generalstation_select.selectmenu( "refresh" );
		updatePlots();		
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));});
}

var updatePlots = function() {
	var generalstationName = generalstation_select.val();
	plot_select.empty();	
	$.get("/tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_select.append(new Option(row[0],row[0]));})
		//plot_select.selectmenu( "refresh" );
	}).fail(function() {plot_select.append(new Option("[error]","[error]"));});
}

var runQueryPlot = function() {
	getID("result").innerHTML = "query...";
	var plotName = plot_select.val();
	$.get("/tsdb/sensor_list?plot="+plotName).done(function(data) {
		getID("result").innerHTML = "";
		sensors = splitData(data);
		$.each(sensors, function(i,row) {addDiagram(plotName,row[0],row[1],row[2]);})
	}).fail(function() {getID("result").innerHTML = "error";});
}

var addDiagram = function(plotName, sensorName, sensorDesc, sensorUnit) {
	var sensorResult = getID("result").appendChild(document.createElement("div"));
	var sensorResultTitle = sensorResult.appendChild(document.createElement("div"));
	sensorResultTitle.innerHTML += "query "+sensorName+"...";
	var aggregationName = aggregation_select.val();
	var image = new Image();
	sensorResult.appendChild(image);
	image.onload = function() {
		sensorResultTitle.innerHTML = sensorName+": "+sensorDesc+" - "+sensorUnit;
	}
	image.onerror = function() {	
		sensorResultTitle.innerHTML = sensorName+": no data";
		sensorResultTitle.style.color = "grey";
		sensorResult.removeChild(image);
	}
	image.src = "/tsdb/query_image?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName;	
}