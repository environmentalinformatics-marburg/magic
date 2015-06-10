var url_base = "../";
var url_plot_info = url_base + "tsdb/plot_info";	
	
var map;

function document_ready() {
	var mapOptions = { 	zoom: 11, 
						center: new google.maps.LatLng(-3.1738427, 37.3574291),
						mapTypeId: google.maps.MapTypeId.TERRAIN,
						streetViewControl: false,
						panControl: false
					};
	map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
	
	$.get(url_plot_info+"?region=KI").done(function(plots) {
		for(var i in plots) {
			var plot = plots[i];
			if(plot.lat!=undefined && plot.lon!=undefined) {	  
				var myLatlng = new google.maps.LatLng(plot.lat, plot.lon);
				//console.log(plot.name+"  "+plot.lat,"  "+plot.lon);	
				
				var populationOptions = {
					strokeColor: '#FF0000',
					strokeOpacity: 1.0,
					strokeWeight: 2,
					fillColor: '#FF0000',
					fillOpacity: 0.5,
					map: map,
					center: myLatlng,
					radius: 100,
					title: plot.name
				};			
				var circle = new google.maps.Circle(populationOptions);
				
				var marker = new MarkerWithLabel({
				   position: myLatlng,
				   map: map,
				   labelContent: plot.name,
				   //labelClass: "labels", // the CSS class for the label
				   //labelInBackground: false,
				   icon: 'plot_icon.png'
				 });
				 
				/*var contentString = "<h1>"+plot.name+"</h1>";
				var infowindow = new google.maps.InfoWindow({content: contentString});
				google.maps.event.addListener(marker, 'click', function() {infowindow.open(map,marker);});*/
			}
		}
	}).fail(function() {sensor_select.append(new Option("[error]","[error]"));decTask();});	
} // END document_ready 
