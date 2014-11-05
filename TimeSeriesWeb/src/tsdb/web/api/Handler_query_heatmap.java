package tsdb.web.api;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.PrintWriter;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Locale;
import java.util.Map;

import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;

import tsdb.DataQuality;
import tsdb.Sensor;
import tsdb.SensorCategory;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.raw.TsEntry;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;
import tsdb.web.TimeSeriesDiagram;
import tsdb.web.TimeSeriesHeatMap;
import tsdb.web.TimeSeriesPainterGraphics2D;

public class Handler_query_heatmap extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();

	public Handler_query_heatmap(RemoteTsDB tsdb) {
		super(tsdb, "query_heatmap");
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);
		response.setContentType("image/png");

		String plot = request.getParameter("plot");
		if(plot==null) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		String sensorName = request.getParameter("sensor");

		if(sensorName==null) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
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
			TimestampSeries ts = tsdb.plot(null, plot, new String[]{sensorName}, AggregationInterval.HOUR, dataQuality, isInterpolated);
			if(ts==null) {
				log.error("TimestampSeries null: "+plot);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			
			BufferedImage bufferedImage = new BufferedImage(1500, 24*4, java.awt.image.BufferedImage.TYPE_INT_RGB);

			TimeSeriesPainterGraphics2D tsp = new TimeSeriesPainterGraphics2D(bufferedImage);

			switch(sensorName) {
			case "Ta_200":
			case "Ta_10":
			case "Ts_5":
			case "Ts_10":
			case "Ts_20":
			case "Ts_50":
			case "Tsky":
			case "Tgnd":
			case "Trad":
				tsp.setIndexedColorRange(-10, 30);
				break;
			case "Albedo":
				tsp.setIndexedColorRange(0.1f, 0.3f);
				break;
			case "rH_200":
				tsp.setIndexedColorRange(0, 100);
				break;
			case "SM_10":
			case "SM_15":
			case "SM_20":
			case "SM_30":
			case "SM_40":
			case "SM_50":
				tsp.setIndexedColorRange(20, 55);
				break;
			case "B_01":
			case "B_02":
			case "B_03":
			case "B_04":
			case "B_05":
			case "B_06":
			case "B_07":
			case "B_08":
			case "B_09":
			case "B_10":
			case "B_11":
			case "B_12":
			case "B_13":
			case "B_14":
			case "B_15":
			case "B_16":
			case "B_17":
			case "B_18":
			case "B_19":
			case "B_20":
			case "B_21":
			case "B_22":
			case "B_23":
			case "B_24":
			case "B_25":
			case "B_26":
			case "B_27":
			case "B_28":
			case "B_29":
			case "B_30":
			case "Rainfall":
				tsp.setIndexedColorRange(0, 3);
				break;
			case "Fog":
				tsp.setIndexedColorRange(0, 0.3f);
				break;
			case "SWDR_300":
				tsp.setIndexedColorRange(0, 1000);
				break;
			case "SWUR_300":
				tsp.setIndexedColorRange(0, 200);
				break;
			case "LWDR_300":
				tsp.setIndexedColorRange(250, 450);
				break;
			case "LWUR_300":
				tsp.setIndexedColorRange(300, 520);
				break;
			case "PAR_200": //no data
			case "PAR_300":
				tsp.setIndexedColorRange(0, 2000);
				break;
			case "P_RT_NRT":
				tsp.setIndexedColorRange(0, 0.2f);
				break;
			case "P_container_RT":
			case "P_container_NRT":
				tsp.setIndexedColorRange(0, 600);
				break;
			case "Rn_300":
				tsp.setIndexedColorRange(-70, 700);
				break;
			case "WD": //no data
				tsp.setIndexedColorRange(0, 360);
				break;
			case "WV":
				tsp.setIndexedColorRange(0, 9);
				break;
			case "WV_gust":
				tsp.setIndexedColorRange(0, 20);
				break;						
			case "p_QNH":
				tsp.setIndexedColorRange(980, 1040);
				break;
			case "P_RT_NRT_01": //few data?
			case "P_RT_NRT_02": //few data?
			case "F_RT_NRT_01": //few data?
			case "F_RT_NRT_02": //few data?
			case "T_RT_NRT_01": //few data?
			case "T_RT_NRT_02": //few data?
				tsp.setIndexedColorRange(0, 2);
				break;
			case "swdr_01": //range?
				tsp.setIndexedColorRange(0, 1200);
				break;
			case "swdr_02": //range?
				tsp.setIndexedColorRange(0, 30);
				break;

			case "par_01": //few data?
			case "par_02": //few data?
			case "p_200": // not in schema?
			case "T_CNR": // not in schema?						
			default:
				tsp.setIndexedColorRange(-10, 30);
			}

			new TimeSeriesHeatMap(ts).draw(tsp);

			try {
				ImageIO.write(bufferedImage, "png", response.getOutputStream());
				response.setStatus(HttpServletResponse.SC_OK);
			} catch (IOException e) {
				log.error(e);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			}
		} catch (Exception e) {
			log.error(e);
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}
}
