var url_base = "../";

var url_region_list = url_base+"tsdb/region_list";
var url_generalstation_list = url_base+"tsdb/generalstation_list";
var url_plot_list = url_base+"tsdb/plot_list";
var url_plotstation_list = url_base+"tsdb/plotstation_list";
var url_sensor_list = url_base+"tsdb/sensor_list";
var url_query_diagram = url_base+"tsdb/query_image";

var time_year_text = ["[all]","2008","2009","2010","2011","2012","2013","2014","2015"];
var time_month_text = ["year","jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"];
var aggregation_text = ["raw","hour","day","week","month","year"];
var quality_name = ["no", "physical", "step", "empirical"];
var quality_text = ["0: no","1: physical","2: physical + step","3: physical + step + empirical"];

var tasks = 0;

var region_select;
var generalstation_select;
var plot_select;
var station_select;
var time_year_select;
var time_month_select;
var aggregation_select;
var quality_select;

function getID(id) {
	return document.getElementById(id);
}

function splitData(data) {
	var lines = data.split(/\n/);
	var rows = [];
	for (var i in lines) {
		if(lines[i].length>0) {
			rows.push(lines[i].split(';'));
		}
	}
	return rows;
}

function ready_to_run(ready) {
	$(".blockable").prop( "disabled",!ready);
	onStationChange();
}

function incTask() {
	ready_to_run(false);
	tasks++;	
	getID("status").innerHTML = "busy ("+tasks+")...";
}

function decTask() {
	tasks--;
	if(tasks===0) {
		getID("status").innerHTML = "ready";
		ready_to_run(true);
	} else if(tasks<0){
		getID("status").innerHTML = "error";
	} else {
		getID("status").innerHTML = "busy ("+tasks+")...";
	}
}

function document_ready() {
	region_select = $("#region_select");
	generalstation_select = $("#generalstation_select");
	plot_select = $("#plot_select");
	station_select = $("#station_select");
	time_year_select = $("#time_year_select");
	time_month_select = $("#time_month_select");
	aggregation_select = $("#aggregation_select");
	quality_select = $("#quality_select");
	
	getID("region_select").onchange = onRegionChange;
	getID("generalstation_select").onchange = onGeneralstationChange;
	getID("plot_select").onchange = onPlotChange;
	getID("station_select").onchange = onStationChange;
	getID("time_year_select").onchange = onTimeYearChange;
	getID("aggregation_select").onchange = onAggregationChange;
	getID("button_visualise").onclick = onVisualiseClick;

	incTask();	
	updateRegions();
	updateTimeYears();
	updateAggregations();
	updateQualities();
	decTask();
}

function updateRegions() {
	incTask();
	region_select.empty();
	$.get(url_region_list).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_select.append(new Option(row[1],row[0]));});
		onRegionChange();
		decTask();		
	}).fail(function() {region_select.append(new Option("[error]","[error]"));decTask();});
}

function onRegionChange() {
	updateGeneralStations();
}

function updateGeneralStations() {
	incTask();
	var regionName = region_select.val();
	generalstation_select.empty();	
	$.get(url_generalstation_list+"?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {
			generalstation_select.append(new Option(row[1],row[0]));
		})		
		onGeneralstationChange();
		decTask();	
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));decTask();});
}

function onGeneralstationChange() {
	updatePlots();
}

function updatePlots() {
	incTask();
	var generalstationName = generalstation_select.val();
	plot_select.empty();	
	$.get(url_plot_list+"?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_select.append(new Option(row[0],row[0]));})
		onPlotChange();
		decTask();
	}).fail(function() {plot_select.append(new Option("[error]","[error]"));decTask();});
}

function onPlotChange() {
	updateStations();
}

function updateStations() {
	incTask();
	var plotName = plot_select.val();
	station_select.empty();	
	$.get(url_plotstation_list+"?plot="+plotName).done(function(data) {
		var rows = splitData(data);
		if(rows.length>0) {
			station_select.append(new Option("[unified]","[unified]"));
		}
		$.each(rows, function(i,row) {station_select.append(new Option(row[0],row[0]));})
		onStationChange();
		decTask();
	}).fail(function() {station_select.append(new Option("[error]","[error]"));decTask();});
}

function onStationChange() {
	if(station_select.val()!=undefined) {
		//getID("button_visualise").disabled = false;
		$("#div_station_select").show();
	} else {
		//getID("button_visualise").disabled = true;
		$("#div_station_select").hide();
	}
}

function onVisualiseClick() {
	incTask();
	getID("div_result").innerHTML = "query...";
	var plotName = plot_select.val();
	var sensorQuery = "plot="+plotName;
	if(station_select.val()!=undefined && station_select.val()!="[unified]") {
		var stationName = station_select.val();
		sensorQuery = "station="+stationName;
		plotName += ":"+stationName;
	}
	$.get(url_sensor_list+"?"+sensorQuery).done(function(data) {
		getID("div_result").innerHTML = "";
		sensors = splitData(data);
		$.each(sensors, function(i,row) {addDiagram(plotName,row[0],row[1],row[2]);})
		decTask();
	}).fail(function() {getID("div_result").innerHTML = "error";decTask();});
}

function addDiagram(plotName, sensorName, sensorDesc, sensorUnit) {
	incTask();
	var sensorResult = getID("div_result").appendChild(document.createElement("div"));
	var sensorResultTitle = sensorResult.appendChild(document.createElement("div"));
	sensorResultTitle.innerHTML += "query "+sensorName+"...";
	var aggregationName = aggregation_select.val();
	var qualityName = "step";
	var qualityName = quality_name[quality_select.val()];
	var interpolatedName = "false";
	//var interpolatedName = ""+getID("interpolated").checked;
	var timeParameter = "";
	if(time_year_select.val()!=0) {
		timeParameter = "&year="+time_year_text[time_year_select.val()];
		var month = time_month_select.val();
		if(month!=0) {
			timeParameter += "&month="+month;
		}
	}
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
	image.src = url_query_diagram+"?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName+"&quality="+qualityName+"&interpolated="+interpolatedName+timeParameter;
	decTask();	
}

function updateTimeYears() {
	$.each(time_year_text, function(i,text) {time_year_select.append(new Option(text,i));});
	$.each(time_month_text, function(i,text) {time_month_select.append(new Option(text,i));});
	onTimeYearChange();
}

function onTimeYearChange() {
	if(time_year_select.val()==0) {
		time_month_select.hide();
	} else {
		time_month_select.show();
	}
}

function updateAggregations() {
	$.each(aggregation_text, function(i,text) {aggregation_select.append(new Option(text));});
	aggregation_select.val("hour");
	onAggregationChange();
}

function onAggregationChange() {
	if(aggregation_select.val()=="raw") {
		$("#div_quality_select").hide();
	} else {
		$("#div_quality_select").show();
	}
}

function updateQualities() {
	$.each(quality_text, function(i,text) {quality_select.append(new Option(text,i));});
	quality_select.val(2);
}