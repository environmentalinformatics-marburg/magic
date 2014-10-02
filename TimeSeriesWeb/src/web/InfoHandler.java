package web;

import java.io.IOException;
import java.io.PrintWriter;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Locale;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class InfoHandler extends AbstractHandler implements TsDBLogger{ 
	private final RemoteTsDB tsdb;

	public InfoHandler(RemoteTsDB tsdb) {
		this.tsdb=tsdb;
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {				
		response.setContentType("text/plain;charset=utf-8");

		baseRequest.setHandled(true);
		System.out.println("target "+target);

		PrintWriter writer = response.getWriter();
		

		boolean ret = false;

		switch(target) {
		case "/plots":
			ret = handle_plots(writer);
			break;
		case "/sensors":
			ret = handle_sensors(writer);
			break;
		case "/region_list":
			ret = handle_region_list(writer);
			break;
		case "/generalstation_list": {
			String region = request.getParameter("region");
			if(region!=null) {
				ret = handle_generalstation_list(writer,region);
			}			
			break;
		}
		case "/plot_list": {
			String generalstation = request.getParameter("generalstation");
			if(generalstation!=null) {
				ret = handle_plot_list(writer,generalstation);
			}			
			break;
		}
		case "/sensor_list": {
			String plot = request.getParameter("plot");
			if(plot!=null) {
				ret = handle_sensor_list(writer,plot);
			} else {
				log.warn("wrong call");
			}
			break;
		}
		case "/query": {
			String plot = request.getParameter("plot");
			String sensor = request.getParameter("sensor");
			String aggregation = request.getParameter("aggregation");
			if(plot!=null&&sensor!=null&&aggregation!=null) {
				ret = handle_query(writer,plot,sensor,aggregation);
			} else {
				log.warn("wrong call");
			}
			break;
		}
		default:
			ret = handle_error(writer, target);
		}

		if(ret) {
			response.setStatus(HttpServletResponse.SC_OK);
		} else {
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}

	private boolean handle_query(PrintWriter writer, String plot, String sensor, String aggregation) {
		try {
			AggregationInterval agg = AggregationInterval.parse(aggregation);
			if(agg!=null) {
				TimestampSeries ts = tsdb.plot(null, plot, new String[]{sensor}, agg, DataQuality.STEP, false);
				if(ts!=null) {
					TsIterator it = ts.tsIterator();
					while(it.hasNext()) {
						TimeSeriesEntry e = it.next(); 
						writer.print(TimeConverter.oleMinutesToText(e.timestamp)+";");
						float value = e.data[0];
						if(Float.isNaN(value)) {
							value = 0f;
						}
						writer.format(Locale.ENGLISH,"%.2f", value);
						if(it.hasNext()) {
							writer.print('\n');
						}
					}
					return true;
				} else {
					log.warn("no data");
					return false;
				}
			} else {
				return false;
			}
		} catch (RemoteException e) {
			log.warn(e);
			return false;
		}

	}

	private boolean handle_plots(PrintWriter writer) {
		try {
			PlotInfo[] plotInfos = tsdb.getPlotInfos();
			for(PlotInfo plotInfo:plotInfos) {
				writer.println(plotInfo.toString());
			}
			return true;
		} catch (Exception e) {
			return false;
		}
	}

	private boolean handle_sensors(PrintWriter writer) {
		try {
			Sensor[] sensors = tsdb.getSensors();
			for(Sensor sensor:sensors) {
				writer.println(sensor.name+"  "+sensor.description+"  "+sensor.unitDescription);
			}
			return true;
		} catch (Exception e) {
			return false;
		}
	}

	private boolean handle_error(PrintWriter writer, String target) {
		writer.println("error: unknown query: "+target);
		return false;
	}

	private boolean handle_region_list(PrintWriter writer) {
		try {
			Region[] regions = tsdb.getRegions();
			if(regions!=null) {
				String[] webList = Arrays.stream(regions).map(r->r.name+";"+r.longName).toArray(String[]::new);
				writeStringArray(writer, webList);
				return true;
			} else {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
	}

	private boolean handle_generalstation_list(PrintWriter writer, String regionName) {
		try {
			GeneralStationInfo[] generalStationInfos = tsdb.getGeneralStationInfos(regionName);
			if(generalStationInfos!=null) {
				String[] webList = Arrays.stream(generalStationInfos).map(g->g.name+";"+g.longName).toArray(String[]::new);
				writeStringArray(writer, webList);
				return true;
			} else {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
	}

	private boolean handle_plot_list(PrintWriter writer, String generalstationName) {
		try {
			PlotInfo[] plotInfos = tsdb.getPlotInfos();
			if(plotInfos!=null) {
				String[] webList = Arrays.stream(plotInfos)
						.filter(p->p.generalStationInfo.name.equals(generalstationName))
						.map(p->p.name)
						.toArray(String[]::new);
				//String[] webList = Arrays.stream(generalStationInfos).map(g->g.name+","+g.longName).toArray(String[]::new);
				writeStringArray(writer, webList);
				return true;
			} else {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
	}

	private boolean handle_sensor_list(PrintWriter writer, String plot) {
		try {
			String[] sensorNames = tsdb.getPlotSchema(plot);
			Map<String, Integer> sensorMap = Util.stringArrayToMap(sensorNames);
			Sensor[] sensors = tsdb.getSensors();
			String[] webList = Arrays.stream(sensors)
					.filter(s->sensorMap.containsKey(s.name)&&s.isAggregable())
					.map(s->s.name+";"+s.description+";"+s.unitDescription)
					.toArray(String[]::new);


			//String[] webList = 
			if(webList!=null) {
				writeStringArray(writer, webList);
				return true;
			} else {
				log.warn("null");
				System.out.println("null");
				//log.warn("null: "+plot);
				return false;
			}			
		} catch (Exception e) {
			log.warn(e);
			System.out.println(e);
			return false;
		}
	}

	private static void writeStringArray(PrintWriter writer, String[] array) {
		if(array==null) {
			return;
		}
		boolean notFirst = false;
		for(String s:array) {
			if(notFirst) {
				writer.print('\n');
			}
			writer.print(s);
			notFirst = true;
		}
	}
}
