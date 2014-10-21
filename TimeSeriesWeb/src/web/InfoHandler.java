package web;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.json.JSONObject;
import org.json.JSONWriter;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.SensorCategory;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TsEntry;
import tsdb.raw.TimestampSeries;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Pair;
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
		log.warn("target "+request.getRequestURI());
		



		boolean ret = false;

		switch(target) {
		case "/plots":
			ret = handle_plots(response.getWriter());
			break;
		case "/sensors":
			ret = handle_sensors(response.getWriter());
			break;
		case "/region_list":
			ret = handle_region_list(response.getWriter());
			break;
		case "/generalstation_list": {
			String region = request.getParameter("region");
			if(region!=null) {
				ret = handle_generalstation_list(response.getWriter(),region);
			}			
			break;
		}
		case "/plot_list": {
			String generalstation = request.getParameter("generalstation");
			if(generalstation!=null) {
				ret = handle_plot_list(response.getWriter(),generalstation);
			}			
			break;
		}
		case "/region_plot_list": {
			String region = request.getParameter("region");
			if(region!=null) {
				ret = handle_region_plot_list(response.getWriter(),region);
			}			
			break;
		}		
		case "/sensor_list": {
			String plot = request.getParameter("plot");
			if(plot!=null) {
				ret = handle_sensor_list(response.getWriter(),plot);
			} else {
				log.warn("wrong call");
			}
			break;
		}
		case "/general_station_sensor_list": {
			String general_station = request.getParameter("general_station");
			if(general_station!=null) {
				ret = handle_general_station_sensor_list(response.getWriter(),general_station);
			} else {
				log.warn("wrong call");
			}
			break;
		}
		case "/region_sensor_list": {
			String region = request.getParameter("region");
			if(region!=null) {
				ret = handle_region_sensor_list(response.getWriter(),region);
			} else {
				log.warn("wrong call");
			}
			break;
		}		
		case "/query": {
			String plot = request.getParameter("plot");
			String sensor = request.getParameter("sensor");
			String aggregation = request.getParameter("aggregation");
			String quality = request.getParameter("quality");
			String interpolated = request.getParameter("interpolated");
			if(plot!=null&&sensor!=null&&aggregation!=null) {
				ret = handle_query(response.getWriter(),plot,sensor,aggregation,quality,interpolated);
			} else {
				log.warn("wrong call");
			}
			break;
		}
		case "/query_image": {
			String plot = request.getParameter("plot");
			String sensor = request.getParameter("sensor");
			String aggregation = request.getParameter("aggregation");
			String quality = request.getParameter("quality");
			String interpolated = request.getParameter("interpolated");
			if(plot!=null&&sensor!=null&&aggregation!=null) {
				ret = handle_query_image(response,plot,sensor,aggregation,quality,interpolated);
			} else {
				log.warn("wrong call");
			}
			break;
		}

		case "/execute_console_command": {
			response.setContentType("application/json");
			BufferedReader reader = new BufferedReader(new InputStreamReader(request.getInputStream()));
			ret = handle_execute_console_command(reader, response.getWriter());
			break;
		}
		case "/console_comand_get_output": {
			response.setContentType("application/json");
			String commandThreadIdText = request.getParameter("commandThreadId");
			if(commandThreadIdText!=null) {
				Long commandThreadId = null;
				try {
					commandThreadId = Long.parseLong(commandThreadIdText);
				} catch(Exception e) {
					log.warn(e);
				}
				if(commandThreadId!=null) {
					ret = handle_console_comand_get_output(commandThreadId, response.getWriter());
				}
			} else {
				log.warn("wrong call");
			}
			break;
		}
		default:
			ret = handle_error(response.getWriter(), target);
		}

		if(ret) {
			response.setStatus(HttpServletResponse.SC_OK);
		} else {
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}

	private boolean handle_console_comand_get_output(Long commandThreadId, PrintWriter writer) {
		try {
			Pair<Boolean, String[]> pair = tsdb.console_comand_get_output(commandThreadId);
			JSONWriter json_output = new JSONWriter(writer);
			json_output.object();			
			json_output.key("running");
			json_output.value(pair.a);
			json_output.key("output_lines");
			json_output.array();
			for(String line:pair.b) {
				json_output.value(line);
			}
			json_output.endArray();
			json_output.endObject();
			return true;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}	
	}

	private boolean handle_execute_console_command(BufferedReader reader, PrintWriter writer) {
		try {
			String jsonline = reader.readLine();
			JSONObject json_input = new JSONObject(jsonline);
			String input_line = json_input.getString("input_line");
			System.out.println("input_line: "+input_line);

			long commandThreadId = tsdb.execute_console_command(input_line);			

			JSONWriter json_output = new JSONWriter(writer);
			json_output.object();
			json_output.key("commandThreadId");
			json_output.value(commandThreadId);			
			json_output.endObject();		

			return true;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}		
	}

	private boolean handle_query(PrintWriter writer, String plot, String sensor, String aggregation, String quality, String interpolated) {
		DataQuality dataQuality = null;
		try {
			dataQuality = DataQuality.parse(quality);
		} catch (Exception e) {
			log.warn(e);
		}
		if(dataQuality==null) {
			dataQuality = DataQuality.STEP;
		}

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
			AggregationInterval agg = AggregationInterval.parse(aggregation);
			if(agg!=null) {
				TimestampSeries ts = tsdb.plot(null, plot, new String[]{sensor}, agg, dataQuality, isInterpolated);
				if(ts!=null) {
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

	private boolean handle_query_image(HttpServletResponse response, String plot, String sensorName, String aggregation, String quality, String interpolated) {
		DataQuality dataQuality = null;
		try {
			dataQuality = DataQuality.parse(quality);
		} catch (Exception e) {
			log.warn(e);
		}
		if(dataQuality==null) {
			dataQuality = DataQuality.STEP;
		}
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
			response.setContentType("image/png");
			AggregationInterval agg = AggregationInterval.parse(aggregation);
			if(agg!=null) {
				TimestampSeries ts = tsdb.plot(null, plot, new String[]{sensorName}, agg, dataQuality, isInterpolated);
				TimestampSeries compareTs = null;
				try {
					compareTs = tsdb.plot(null, plot, new String[]{sensorName}, agg, DataQuality.NO, false);
				} catch(Exception e) {
					log.warn(e);
				}
				if(ts!=null) {
					BufferedImage bufferedImage = new BufferedImage(1500, 400, java.awt.image.BufferedImage.TYPE_INT_RGB);


					Graphics2D gc = bufferedImage.createGraphics();
					gc.setBackground(new Color(255, 255, 255));
					gc.setColor(new Color(0, 0, 0));
					gc.clearRect(0, 0, bufferedImage.getWidth(), bufferedImage.getHeight());
					gc.dispose();


					SensorCategory diagramType = SensorCategory.OTHER;
					try {
						Sensor sensor = tsdb.getSensor(sensorName);
						if(sensor!=null) {
							diagramType = sensor.category;
						}
					} catch(Exception e) {
						log.warn(e);
					}


					new TimeSeriesDiagram(ts, agg, diagramType).draw(new TimeSeriesPainterGraphics2D(bufferedImage),compareTs);

					try {
						//ImageIO.write(bufferedImage, "png", new File("C:/timeseriesdatabase_output/"+"img.png"));
						ImageIO.write(bufferedImage, "png", response.getOutputStream());
						return true;
					} catch (IOException e) {
						e.printStackTrace();
						return false;
					}
				} else {
					return false;
				}

			} else {
				return false;
			}
		} catch (RemoteException e) {
			e.printStackTrace();
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

	private boolean handle_region_plot_list(PrintWriter writer, String regionName) {
		try {
			PlotInfo[] plotInfos = tsdb.getPlotInfos();
			if(plotInfos!=null) {
				String[] webList = Arrays.stream(plotInfos)
						.filter(p->p.generalStationInfo.region.name.equals(regionName))
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

	private boolean handle_general_station_sensor_list(PrintWriter writer, String general_station) {
		try {
			String[] sensorNames = tsdb.getGeneralStationSensorNames(general_station);
			Map<String, Integer> sensorMap = Util.stringArrayToMap(sensorNames);
			Sensor[] sensors = tsdb.getSensors();
			String[] webList = Arrays.stream(sensors)
					.filter(s->sensorMap.containsKey(s.name)&&s.isAggregable())
					.map(s->s.name+";"+s.description+";"+s.unitDescription)
					.toArray(String[]::new);
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

	private boolean handle_region_sensor_list(PrintWriter writer, String region) {
		try {			
			Set<String> sensorNameSet = new TreeSet<String>();
			for(GeneralStationInfo generalStationInfo:tsdb.getGeneralStations()) {
				System.out.println(generalStationInfo.name);
				if(generalStationInfo.region.name.equals(region)) {
					for(String sensorName:tsdb.getGeneralStationSensorNames(generalStationInfo.name)) {
						sensorNameSet.add(sensorName);
					}
				}
			}
			String[] sensorNames = tsdb.getBaseSchema(sensorNameSet.toArray(new String[0]));			
			if(sensorNames!=null) {
				writeStringArray(writer, sensorNames);
				return true;
			} else {
				log.warn("null");
				System.out.println("null");
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
