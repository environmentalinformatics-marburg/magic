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
import tsdb.web.TimeSeriesPainterGraphics2D;

public class Handler_query_image extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();

	public Handler_query_image(RemoteTsDB tsdb) {
		super(tsdb, "query_image");
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
			TimestampSeries ts = tsdb.plot(null, plot, new String[]{sensorName}, agg, dataQuality, isInterpolated);
			if(ts==null) {
				log.error("TimestampSeries null: "+plot);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			TimestampSeries compareTs = null;
			try {
				compareTs = tsdb.plot(null, plot, new String[]{sensorName}, agg, DataQuality.NO, false);
			} catch(Exception e) {
				e.printStackTrace();
				log.warn(e,e);
			}

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
					if(diagramType==null) {
						diagramType = SensorCategory.OTHER;
					}
				}
			} catch(Exception e) {
				log.warn(e);
			}

			new TimeSeriesDiagram(ts, agg, diagramType).draw(new TimeSeriesPainterGraphics2D(bufferedImage),compareTs);

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
