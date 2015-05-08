package tsdb.web.api;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.time.LocalDateTime;

import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;

import tsdb.component.Region;
import tsdb.component.Sensor;
import tsdb.component.SensorCategory;
import tsdb.remote.RemoteTsDB;
import tsdb.util.AggregationInterval;
import tsdb.util.DataQuality;
import tsdb.util.TimeConverter;
import tsdb.util.gui.TimeSeriesDiagram;
import tsdb.util.gui.TimeSeriesPainterGraphics2D;
import tsdb.util.iterator.TimestampSeries;

public class Handler_query_image extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();

	private static final boolean USE_COMPARE_TIMESERIES = false;

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

		boolean boxplot = false;
		if(agg==AggregationInterval.DAY||agg==AggregationInterval.WEEK||agg==AggregationInterval.MONTH||agg==AggregationInterval.YEAR) {
			boxplot = true;
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

		String timeYear = request.getParameter("year");
		Long startTime = null;
		Long endTime = null;
		if(timeYear!=null) {
			try {
				int year = Integer.parseInt(timeYear);
				if(year<2008||year>2015) {
					log.error("year out of range "+year);
					response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
					return;
				}
				String timeMonth = request.getParameter("month");
				if(timeMonth==null) {
					startTime = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(year, 1, 1, 0, 0));
					endTime = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(year, 12, 31, 23, 0));
				} else {
					try {
						int month = Integer.parseInt(timeMonth);
						if(month<1||month>12) {
							log.error("month out of range "+month);
							response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
							return;
						}
						LocalDateTime dateMonth = LocalDateTime.of(year, month, 1, 0, 0);
						startTime = TimeConverter.DateTimeToOleMinutes(dateMonth);
						endTime = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(year, month, dateMonth.toLocalDate().lengthOfMonth(), 23, 0));
					} catch (Exception e) {
						log.error(e);
						response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
						return;
					}	
				}
			} catch (Exception e) {
				log.error(e);
				response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
				return;
			}
		} else {
			Region region = tsdb.getRegionByPlot(plot);
			if(region!=null) {
				startTime = (long) region.viewTimeRange.start;
				endTime = (long) region.viewTimeRange.end;
			} else {			
				startTime = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2008, 1, 1, 0, 0)); ////TODO !!!!!!!!!!!! fixed start and end time
				endTime = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2015, 12, 31, 23, 0)); ///TODO !!!!!!!!!!!!!!!
			}
		}

		try {
			String[] sensorNames;
			if(sensorName.equals("WD")) {
				sensorNames = new String[]{sensorName,"WV"};
			} else {
				sensorNames = new String[]{sensorName};
			}
			String[] validSchema =  tsdb.getValidSchema(plot, sensorNames);
			if(sensorNames.length!=validSchema.length) {
				log.info("sensorName not in plot: "+plot+"  "+sensorName);
				response.setStatus(HttpServletResponse.SC_BAD_REQUEST);				
				return;
			}

			TimestampSeries ts;

			if(boxplot) {
				ts = tsdb.plotQuartile(plot, sensorNames, agg, dataQuality, isInterpolated, startTime, endTime);
			} else {
				ts = tsdb.plot(null, plot, sensorNames, agg, dataQuality, isInterpolated, startTime, endTime);
			}
			
			if(ts==null) {
				log.error("TimestampSeries null: "+plot);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			TimestampSeries compareTs = null;
			if(USE_COMPARE_TIMESERIES) {
				try {
					compareTs = tsdb.plot(null, plot, new String[]{sensorName}, agg, DataQuality.NO, false, startTime, endTime);
				} catch(Exception e) {
					e.printStackTrace();
					log.warn(e,e);
				}
			}

			int imageWidth = 1500;
			int imageHeight = 400;

			String imageWidthText = request.getParameter("width");
			String imageHeightText = request.getParameter("height");
			if(imageWidthText!=null&&imageHeightText!=null) {
				try {
					int w = Integer.parseInt(imageWidthText);
					int h = Integer.parseInt(imageHeightText);
					if(w>=32&&h>=32&&w<100000&&h<100000) {
						imageWidth = w;
						imageHeight = h;
					}
				} catch(Exception e) {
					log.warn(e);
				}
			}



			BufferedImage bufferedImage = new BufferedImage(imageWidth, imageHeight, java.awt.image.BufferedImage.TYPE_INT_RGB);
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

			TimeSeriesDiagram tsd = new TimeSeriesDiagram(ts, agg, diagramType, boxplot);

			if(agg!=null&&startTime!=null&&endTime!=null&&agg==AggregationInterval.RAW) {
				tsd.setDiagramTimestampRange(startTime, endTime);
			}
			tsd.draw(new TimeSeriesPainterGraphics2D(bufferedImage),compareTs);

			try {
				ImageIO.write(bufferedImage, "png", response.getOutputStream());
				response.setStatus(HttpServletResponse.SC_OK);
			} catch (IOException e) {
				log.error(e);
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			}
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}	
}
