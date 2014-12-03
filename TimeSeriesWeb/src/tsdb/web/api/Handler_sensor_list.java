package tsdb.web.api;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;

import tsdb.Sensor;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;

public class Handler_sensor_list extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();

	public Handler_sensor_list(RemoteTsDB tsdb) {
		super(tsdb, "sensor_list");
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);
		response.setContentType("text/plain;charset=utf-8");
		String plot = request.getParameter("plot");
		String general_station = request.getParameter("general_station");
		String region = request.getParameter("region");
		if(!((plot!=null&&general_station==null&&region==null)||(plot==null&&general_station!=null&&region==null)||(plot==null&&general_station==null&&region!=null))) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			String[] sensorNames = null;
			if(plot!=null) {			
				sensorNames = tsdb.getSensorNamesOfPlot(plot);			
			} else if(general_station!=null) {
				sensorNames = tsdb.getSensorNamesOfGeneralStation(general_station);	
			} else if(region!=null){
				Set<String> sensorNameSet = new TreeSet<String>();
				for(GeneralStationInfo generalStationInfo:tsdb.getGeneralStations()) {
					if(generalStationInfo.region.name.equals(region)) {
						for(String sensorName:tsdb.getSensorNamesOfGeneralStation(generalStationInfo.name)) {
							sensorNameSet.add(sensorName);
						}
					}
				}
				sensorNames = sensorNameSet.toArray(new String[0]);
			}
			if(sensorNames==null) {
				log.error("sensorNames null: "+plot);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			//Map<String, Integer> sensorMap = Util.stringArrayToMap(sensorNames);
			Sensor[] sensors = tsdb.getSensors();
			if(sensors==null) {
				log.error("sensors null: "+plot);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			Map<String,Sensor> sensorMap = new HashMap<String, Sensor>();
			for(Sensor sensor:sensors) {
				sensorMap.put(sensor.name, sensor);
			}
			/*String[] webList = Arrays.stream(sensors)
					.filter(s->sensorMap.containsKey(s.name)&&s.isAggregable())
					.map(s->s.name+";"+s.description+";"+s.unitDescription)
					.toArray(String[]::new);*/
			ArrayList<String> webList = new ArrayList<String>();
			for(String sensorName:sensorNames) {
				Sensor s = sensorMap.get(sensorName);
				if(s.isAggregable()) {
					webList.add(s.name+";"+s.description+";"+s.unitDescription);
				}
			}
			
			
			PrintWriter writer = response.getWriter();
			writeStringArray(writer, webList);
			response.setStatus(HttpServletResponse.SC_OK);
		} catch (Exception e) {
			log.error(e);
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}
}
