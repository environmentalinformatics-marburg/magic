package tsdb.web.api;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.swing.JApplet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;
import org.json.JSONString;
import org.json.JSONWriter;

import tsdb.remote.PlotStatus;
import tsdb.remote.RemoteTsDB;
import tsdb.util.TimeConverter;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;

public class Handler_status extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();
	
	private static class JSONFloat implements JSONString {		
		public final float value;		
		public JSONFloat(float value) {
			this.value = value;
		}
		@Override
		public String toJSONString() {
			//return Util.floatToString(value);
			return Float.toString(value);
		}		
	}

	public Handler_status(RemoteTsDB tsdb) {
		super(tsdb, "status");
	}

	//TODO
	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);
		response.setContentType("text/plain;charset=utf-8");
		String generalstationName = request.getParameter("generalstation");
		String regionName = request.getParameter("region");
		if((generalstationName!=null&&regionName!=null)) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			ArrayList<PlotStatus> tsl = null;
			if(generalstationName==null&&regionName==null) {
				tsl = tsdb.getPlotStatuses();
			} else if(generalstationName!=null&&regionName==null){
				tsl = tsdb.getPlotStatusesOfGeneralStation(generalstationName);
			} else if(generalstationName==null&&regionName!=null){
				tsl = tsdb.getPlotStatusesOfRegion(regionName);				
			}
			if(tsl==null) {
				log.error("tsl null");
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			//tsl.sort(PlotStatus.END_COMPARATOR);
			PrintWriter writer = response.getWriter();
			JSONWriter json_output = new JSONWriter(writer);
			json_output.array();
			for(PlotStatus i:tsl) {
				json_output.object();
				json_output.key("plot");
				json_output.value(i.plotID);
				json_output.key("first_timestamp");
				json_output.value(i.firstTimestamp);
				json_output.key("last_timestamp");
				json_output.value(i.lastTimestamp);
				json_output.key("first_datetime");
				json_output.value(TimeConverter.oleMinutesToText(i.firstTimestamp));
				json_output.key("last_datetime");
				json_output.value(TimeConverter.oleMinutesToText(i.lastTimestamp));
				if(Float.isFinite(i.voltage)) {
					json_output.key("voltage");
					json_output.value(new JSONFloat(i.voltage));					
					//json_output.value(i.voltage);
				}
				json_output.endObject();
			}
			json_output.endArray();
			response.setStatus(HttpServletResponse.SC_OK);
		} catch (Exception e) {
			log.error(e);
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}


}
