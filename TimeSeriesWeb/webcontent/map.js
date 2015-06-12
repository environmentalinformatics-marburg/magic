var url_base = "../";

var url_plot_info = url_base + "tsdb/plot_info";
var url_plot_status = url_base + "tsdb/status";	
	
var map;

var plotInfoMap = {};

function document_ready() {
	var mapOptions = { 	zoom: 11, 
						center: new google.maps.LatLng(-3.1738427, 37.3574291),
						mapTypeId: google.maps.MapTypeId.TERRAIN,
						streetViewControl: false,
						panControl: false
					};
	map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);	
	queryPlotInfo();
} // END document_ready 

function queryPlotInfo() {
	$.get(url_plot_info+"?region=KI").done(function(plots) {
		for(var i in plots) {
			var plot = plots[i];
			
			plotInfoMap[plot.name] = plots[i];
			
			//addPlotMarker(plot);
			
		}
		console.log(plotInfoMap);
		queryPlotStatus();
	}).fail(function() {sensor_select.append(new Option("[error]","[error]"));decTask();});		
}

function queryPlotStatus() {
	$.getJSON(url_plot_status+"?region=KI").done(function(intervals) {
		var max_last = 0;
		for(var i in intervals) {
			var interval = intervals[i];
			var plotID = interval.plot;
			var plotInfo = plotInfoMap[plotID]; 
			console.log(plotInfo);
			for (var attrname in plotInfo) {
				interval[attrname] = plotInfo[attrname];
			}
			if(max_last<interval.last_timestamp) {
				max_last = interval.last_timestamp;
			}			
			//console.log(max_last);
			//addPlotMarker(interval);
		}
		for(var i in intervals) {
			var plot = intervals[i];
			var t = max_last - plot.last_timestamp;
			plot.days = t/(60*24);
			var timeMark = "timeMarkOneMonth";
			if(t>60*24*365) {
				timeMark = "timeMarkLost";
			} else if(t>60*24*7*4) {
				timeMark = "timeMarkOneMonth";
			} else if(t>60*24*7*2) {
				timeMark = "timeMarkTwoWeeks";
			} else if(t>60*24*7) {
				timeMark = "timeMarkOneWeek";
			} else {
				timeMark = "timeMarkNow";
			}
			addPlotMarker(plot,timeMark);
		}
		//console.log(intervals);
	}).fail(function() {getID("result").innerHTML = "error";});
}

function addPlotMarker(plot, timeMark) {
	if(plot.lat!=undefined && plot.lon!=undefined) {			
		var myLatlng = new google.maps.LatLng(plot.lat, plot.lon);
		//console.log(plot.name+"  "+plot.lat,"  "+plot.lon);

		var timeMarkColor = '#FF0000';
		if(timeMark!="timeMarkNow") {
			timeMarkColor = '#00FF00'; 
		}
		switch(timeMark) {
			case "timeMarkNow":
				timeMarkColor = '#44ff44';
				break;
			case "timeMarkOneWeek":
				timeMarkColor = '#ffff44';
				break;
			case "timeMarkTwoWeeks":
				timeMarkColor = '#ff9944';
				break;
			case "timeMarkOneMonth":
				timeMarkColor = '#ff4444';
				break;
			case "timeMarkLost":
				timeMarkColor = '#666666';
				break;
			default: //error
				console.log("error unknown marker text: "+timeMark);
				timeMarkColor = '#0000FF';
		}
		
		
		var populationOptions = {
			strokeColor: timeMarkColor,
			strokeOpacity: 1.0,
			strokeWeight: 2,
			fillColor: timeMarkColor,
			fillOpacity: 0.8,
			map: map,
			center: myLatlng,
			radius: 100,
			title: plot.name
		};			
		var circle = new google.maps.Circle(populationOptions);
		
		var marker = new MarkerWithLabel({
		   position: myLatlng,
		   map: map,
		   labelContent: plot.name+"<br>"+parseInt(plot.days),
		   //labelClass: "labels", // the CSS class for the label
		   //labelInBackground: false,
		   icon: 'plot_icon.png'
		 });
		 
		/*var contentString = "<h1>"+plot.name+"</h1>";
		var infowindow = new google.maps.InfoWindow({content: contentString});
		google.maps.event.addListener(marker, 'click', function() {infowindow.open(map,marker);});*/
	}
}

