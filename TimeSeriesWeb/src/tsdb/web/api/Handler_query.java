package tsdb.web.api;

import java.io.IOException;
import java.io.PrintWriter;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Locale;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;

import tsdb.DataQuality;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.raw.TsEntry;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class Handler_query extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();

	public Handler_query(RemoteTsDB tsdb) {
		super(tsdb, "query");
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);
		response.setContentType("text/plain;charset=utf-8");

		String plot = request.getParameter("plot");
		if(plot==null) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		String sensor = request.getParameter("sensor");

		if(sensor==null) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}

		String aggregation = request.getParameter("aggregation");
		AggregationInterval agg = AggregationInterval.HOUR;
		if(aggregation!=null) {
			try {
				agg = AggregationInterval.parse(aggregation);
				if(agg==null) {
					agg = AggregationInterval.HOUR;
				}
			} catch (Exception e) {
				log.warn(e);
			}
		}

		String quality = request.getParameter("quality");
		DataQuality dataQuality = DataQuality.STEP;
		if(quality!=null) {
			try {
				dataQuality = DataQuality.parse(quality);
				if(dataQuality==null) {
					dataQuality = DataQuality.STEP;
				}
			} catch (Exception e) {
				log.warn(e);
			}
		}

		String interpolated = request.getParameter("interpolated");
		boolean isInterpolated = false;
		if(interpolated!=null) {
			switch(interpolated) {
			case "true":
				isInterpolated = true;
				break;
			case "false":
				isInterpolated = false;
				break;
			default:
				log.warn("unknown input");
				isInterpolated = false;				
			}
		}		

		try {
			TimestampSeries ts = tsdb.plot(null, plot, new String[]{sensor}, agg, dataQuality, isInterpolated, null, null);
			if(ts==null) {
				log.error("TimestampSeries null: "+plot);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			
			PrintWriter writer = response.getWriter();
			TsIterator it = ts.tsIterator();
			while(it.hasNext()) {
				TsEntry e = it.next(); 
				writer.print(TimeConverter.oleMinutesToText(e.timestamp)+";");
				float value = e.data[0];
				if(Float.isNaN(value)) {
					writer.print("NA");
				} else {
					writer.format(Locale.ENGLISH,"%.2f", value);
				}						
				if(it.hasNext()) {
					writer.print('\n');
				}
			}
			response.setStatus(HttpServletResponse.SC_OK);
		} catch (Exception e) {
			log.error(e);
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}
}
