package tsdb.gui.util;


import static tsdb.util.AssumptionCheck.throwNull;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Display;

import tsdb.gui.util.Painter.PosHorizontal;
import tsdb.gui.util.Painter.PosVerical;
import tsdb.util.AggregationInterval;
import tsdb.util.TsEntry;
import tsdb.util.Util;
import tsdb.util.iterator.TimestampSeries;

public class TimeSeriesView {
	
	private final Display display;

	private TimestampSeries timeSeries;
	private AggregationInterval aggregationInterval;	

	//*** range of time series data
	private double dataMinTimestamp;
	private double dataMaxTimestamp;
	private double dataTimestampRange;
	private double dataMinValue;
	private double dataMaxValue;
	private double dataValueRange;
	private double dataCount;
	private double dataSum;

	//*** range of time series data in output view
	private double viewZoomFactor;
	private double viewOffset;

	private double minTimestamp;
	private double maxTimestamp;
	private double timestampRange;
	private double minValue;
	private double maxValue;
	private double valueRange;


	//static final float border = 40;
	static final float borderTop = 10;
	static final float borderBottom = 15;
	static final float borderLeft = 40;
	static final float borderRight = 10;

	//*** range of output window
	int xStart;
	int xEnd;
	int xRange;

	int yStart;
	int yEnd;
	int yRange;

	//*** conversion values
	//double valueOffset;
	double valueFactor;
	//double timestampOffset;
	double timestampFactor;

	//*** colors
	Color color_black;
	Color color_grey;
	Color color_light;

	private String title;

	private TimestampSeries compare_timeSeries;



	public TimeSeriesView(Display display) {
		throwNull(display);
		this.display = display;
		this.timeSeries = null;
		this.aggregationInterval = AggregationInterval.HOUR;
		this.viewZoomFactor = 1;
		this.viewOffset = 0;
		color_black = new Color(display,0,0,0);
		color_grey = new Color(display,190,190,190);
		color_light = new Color(display,220,220,220);
	}

	public double getZoomFactor() {
		return viewZoomFactor;
	}

	public void setZoomFactor(double zoomFactor) {
		this.viewZoomFactor = zoomFactor;
		updateRangeOfOutputView();
	}

	public double getViewOffset() {
		return viewOffset;
	}

	public void setViewOffset(double viewOffset) {
		this.viewOffset = viewOffset;
		updateRangeOfOutputView();
	}

	public TimestampSeries getTimeSeries() {
		return timeSeries;
	}

	public void updateViewData(TimestampSeries timeSeries, AggregationInterval aggregationInterval, String title, TimestampSeries compare_timeSeries) {

		this.timeSeries = timeSeries;
		this.aggregationInterval = aggregationInterval;
		this.title = title;
		this.compare_timeSeries = compare_timeSeries;

		if(timeSeries!=null) {
			updateRangeOfTimeSeriesData();
			updateRangeOfOutputView();
		}	
	}

	void updateRangeOfTimeSeriesData() {
		dataMinValue = Float.MAX_VALUE;
		dataMaxValue = -Float.MAX_VALUE;
		dataCount = 0f;
		dataSum = 0f;

		for(TsEntry entry:timeSeries) {
			float value = entry.data[0];
			if(!Float.isNaN(value)) {
				if(value<dataMinValue) {
					dataMinValue = value;						
				}
				if(value>dataMaxValue) {
					dataMaxValue = value;						
				}
				dataCount++;
				dataSum += value;
			}
		}

		dataValueRange = dataMaxValue-dataMinValue;

		dataMinTimestamp = timeSeries.getFirstTimestamp();
		dataMaxTimestamp = timeSeries.getLastTimestamp();
		dataTimestampRange = dataMaxTimestamp-dataMinTimestamp;		
	}

	public void setTimeRange(long minTimestamp, long maxTimestamp) {
		this.minTimestamp = minTimestamp;
		this.maxTimestamp = maxTimestamp;
		this.timestampRange = maxTimestamp-minTimestamp;
		updateDataWindowConversionValues();
	}

	void updateRangeOfOutputView() {

		minTimestamp = viewOffset+dataMinTimestamp;
		maxTimestamp = viewOffset+dataMinTimestamp+(dataTimestampRange/viewZoomFactor);
		timestampRange = maxTimestamp-minTimestamp;

		minValue = dataMinValue;
		maxValue = dataMaxValue;
		valueRange = maxValue-minValue;

		double scale = (int) (Math.log((dataValueRange))/Math.log(10));
		//System.out.println("scale"+scale+" -> "+Math.pow(10, scale));
		float grid = (float) Math.pow(10, scale);

		//System.out.println(";"+dataMinValue+" "+dataMaxValue+" "+Math.abs(dataMinValue%grid)+" "+Math.abs(dataMaxValue%grid));

		double absRestMin = Math.abs(dataMinValue%grid);
		if(dataMinValue>0) {
			minValue = dataMinValue-absRestMin;
		} else {
			if(absRestMin>0) {
				minValue = dataMinValue-(grid-absRestMin);
			}
		}

		double absRestMax = Math.abs(dataMaxValue%grid);
		if(absRestMax>0) {
			if(absRestMax>0) {
				maxValue = dataMaxValue+(grid-absRestMax);
			}
		} else {
			maxValue = dataMaxValue+absRestMax;
		}


		valueRange = maxValue-minValue;

		//System.out.println(":"+minValue+" "+maxValue);

	}

	public void updateWindow(int xPos, int yPos, int width, int height) {
		//updateRangeOfOutputWindow(xStart,xStart+width,yPos+height,yPos,false);
		updateRangeOfOutputWindow(xPos,yPos,xPos+width,yPos+height, true);
	}

	void updateRangeOfOutputWindow(int w, int h) {
		updateRangeOfOutputWindow(0, 0, w, h, true);
	}

	void updateRangeOfOutputWindow(int xStart, int yStart, int xEnd, int yEnd, boolean withBorder) {
		if(withBorder) {
			this.xStart = (int) (xStart+borderLeft);
			this.xEnd = (int) (xEnd-borderRight);
			this.yStart = (int) (yStart+borderTop);
			this.yEnd = (int) (yEnd-borderBottom);

			this.xRange = this.xEnd-this.xStart;
			this.yRange = this.yEnd-this.yStart;
		} else {
			this.xStart = xStart;
			this.xEnd = xEnd;
			this.yStart = yStart;
			this.yEnd = yEnd;

			this.xRange = this.xEnd-this.xStart;
			this.yRange = this.yEnd-this.yStart;
		}
	}

	void updateDataWindowConversionValues() {
		/*valueOffset = -minValue;
		valueFactor = yRange/valueRange;
		timestampOffset = -minTimestamp;
		timestampFactor = xRange/(timestampRange+1); //???*/

		valueFactor = yRange/valueRange;
		timestampFactor = xRange/timestampRange; //???? xRange/(timestampRange+1)


	}



	private void drawGrid(GC gc) {

		//drawXGrid(gc);
		TimeScalePainter tsp = new TimeScalePainter();
		tsp.setColor(display);
		tsp.paint(gc, minTimestamp, maxTimestamp, xStart, xEnd, yStart, yEnd, yEnd);
		drawYGrid(gc);


	}



	private void drawYGrid(GC gc) {
		int maxLines = (int) (yRange/17);
		/*double lineStep = valueRange/maxLines;
		
		
		
		lineStep = lineStep+(10d-lineStep%10d);

		if(valueRange/lineStep<=(maxLines/2d)) {
			lineStep = lineStep/2d;
		}*/
		
		
		
		
		double minLineStep = valueRange/maxLines;
		double logMinLineStep = Math.pow(10d, Math.ceil(Math.log10(minLineStep)));
		double lineStep = logMinLineStep;
		if((valueRange/(lineStep/5))<=maxLines) {
			lineStep /= 5d;
		} else if((valueRange/(lineStep/2))<=maxLines) {
			lineStep /= 2d;
		}
		
		double mod = minValue%lineStep;
		double lineStart = mod>0d?minValue+lineStep-mod:minValue-mod;
		
		System.out.println("logMinLineStep: "+logMinLineStep+"   minValue: "+minValue+"   maxValue: "+maxValue+"   valueRange: "+valueRange+"  lineStart: "+lineStart+"  lineStep: "+lineStep+"  minValue%lineStep: "+(minValue%lineStep));
		drawYGrid(gc,lineStart,lineStep);
	}


	private void drawYGrid(GC gc, double lineStart, double lineStep) {
		Color color_light_blue = new Color(display,220,220,255);

		//double line = minValue;
		double line = lineStart;

		while(line<=maxValue) {			
			int y = valueToGraph(line);
			gc.setForeground(color_light_blue);
			gc.drawLine(xStart , y, xEnd, y);
			gc.setForeground(color_black);
			
			String valueText;
			if(lineStep>=1d) {
				valueText = Util.doubleToString0(line);
			} else if(lineStep>=0.1d) {
				valueText = Util.doubleToString1(line);
			} else if(lineStep>=0.01d) {
				valueText = Util.doubleToString2(line);
			} else {
				valueText = Util.doubleToStringFull(line);
			}
			
			Painter.drawText(valueText, gc, xStart, y, PosHorizontal.RIGHT, PosVerical.CENTER);
			line+=lineStep;
		}


	}





	private int timestampToGraph(double timestamp) {
		return (int) (xStart + (timestamp-minTimestamp)*timestampFactor);
	}

	private int valueToGraph(double yValue) {
		return (int) (yEnd - ((yValue - minValue)*valueFactor));
	}

	/*private static LocalDateTime timestampToDataTime(double timestamp) {
		return TimeConverter.oleMinutesToLocalDateTime((long)timestamp);
	}*/


	private void drawXYAxis(GC gc) {

		gc.setForeground(color_black);

		//gc.drawText(""+timestampToDataTime(dataMinTimestamp), xStart, yStart+2);
		//gc.drawText(""+timestampToDataTime(dataMaxTimestamp), xEnd-70, yStart+2);

		//gc.drawText(Util.floatToString(minValue), 3, yStart-10);
		//gc.drawText(Util.floatToString(maxValue), 3, yEnd-10);


		gc.setForeground(color_grey);

		gc.drawLine(xStart , yStart, xEnd, yStart); //x-Aches
		gc.drawLine(xStart , yEnd, xEnd, yEnd); //x-Grenze
		gc.drawLine(xEnd , yStart, xEnd, yEnd); // y-Achse
		gc.drawLine(xStart , yStart, xStart, yEnd); // y-Grenze

		gc.setForeground(color_black);
		int zeroY = valueToGraph(0d);
		if(yStart<=zeroY&&zeroY<=yEnd) {
			gc.drawLine(xStart , zeroY, xEnd, zeroY);
		}



		//int zero_y = (int) ((height-minValue)*valueFactor+border);


		//  min  zero max

		//  height   * (value-min) 
		//----------------- 
		//(max-min)


		//int y = (int) ((yRange-(/*0f-*/minValue)*valueFactor)+border);

		//int zero_y = (int) ((int) yRange-(yRange*(/*0-*/minValue)/(maxValue-minValue))+border);
		//gc.drawLine(xStart , zero_y, xEnd, zero_y);

		//System.out.println(yStart+" "+zero_y+" "+y+" "+yEnd);
	}


	public void paintCanvas(GC gc, Point point) {
		if(timeSeries!=null) {

			Font old = gc.getFont();
			FontData fd = old.getFontData()[0];
			fd.setHeight(20);
			gc.setFont(new Font(display, fd));
			gc.setForeground(new Color(display,200,200,200));
			Painter.drawText(title, gc, 50, 20, PosHorizontal.LEFT, PosVerical.TOP);
			gc.setFont(old);


			if(point!=null) {
				updateRangeOfOutputWindow(point.x,point.y);
			}

			updateDataWindowConversionValues();
			
			Color color_bluegreen = new Color(display,190,240,190);
			int avg = valueToGraph(dataSum/dataCount);
			gc.setForeground(color_bluegreen);
			gc.drawLine(xStart, avg, xEnd, avg);
			
			drawGrid(gc);

			drawXYAxis(gc);

			if(compare_timeSeries!=null) {

				Color color_red = new Color(display,240,0,0);
				Color color_redgrey = new Color(display,240,190,190);

				drawTimeSeries(gc, compare_timeSeries, color_red, color_redgrey);
			}

			drawTimeSeries(gc,timeSeries,color_black,color_grey);			
		}

	}

	private void drawTimeSeries(GC gc, TimestampSeries used_timeseries, Color clrValues, Color clrConnections) {
		int aggregationTimeInterval = 60;
		switch(aggregationInterval) {
		case HOUR:
			aggregationTimeInterval=60;
			break;
		case DAY:
			aggregationTimeInterval=1*24*60;
			break;
		case WEEK:
			aggregationTimeInterval=7*24*60;
			break;
		case MONTH:
			aggregationTimeInterval=30*24*60;//28*24*60;
			break;
		case YEAR:
			aggregationTimeInterval=365*24*60;
			break;
		default:
			System.out.println("error in agg");
		}

		Integer prevX = null;
		Integer prevY = null;

		List<int[]> connectLineList = new ArrayList<int[]>(used_timeseries.entryList.size());
		List<int[]> valueLineList = new ArrayList<int[]>(used_timeseries.entryList.size());

		for(TsEntry entry:used_timeseries) {	
			float value = entry.data[0];
			double timestamp = entry.timestamp;
			if(!Float.isNaN(value)) {				
				int x0 = timestampToGraph(timestamp);
				int x1 = timestampToGraph(timestamp+aggregationTimeInterval);
				int y = valueToGraph(value);
				if(prevX!=null) {
					connectLineList.add(new int[]{x0, prevY, x0, y});
				}
				valueLineList.add(new int[]{x0, y, x1, y});
				prevX = x1;
				prevY = y;
			} else {
				prevX = null;
				prevY = null;
			}

		}

		//*** start drawing

		gc.setForeground(clrConnections);
		for(int[] e:connectLineList) {
			gc.drawLine(e[0], e[1], e[2], e[3]);
		}

		gc.setForeground(clrValues);
		for(int[] e:valueLineList) {
			gc.drawLine(e[0], e[1], e[2], e[3]);
		}
		//*** end drawing
	}
}
