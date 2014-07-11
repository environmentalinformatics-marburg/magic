package gui;


import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.widgets.Canvas;

import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.Util;

public class TimeSeriesView {

	private Canvas canvas;

	private TimestampSeries timeSeries;
	private AggregationInterval aggregationInterval;	

	//*** range of time series data
	private double dataMinTimestamp;
	private double dataMaxTimestamp;
	private double dataTimestampRange;
	private double dataMinValue;
	private double dataMaxValue;
	private double dataValueRange;

	//*** range of time series data in output view
	private double viewZoomFactor;
	private double viewOffset;
	
	private double minTimestamp;
	private double maxTimestamp;
	private double timestampRange;
	private double minValue;
	private double maxValue;
	private double valueRange;


	static final float border = 40;

	//*** range of output window
	int xStart;
	int xEnd;
	int xRange;

	int yStart;
	int yEnd;
	int yRange;

	//*** conversion values
	double valueOffset;
	double valueFactor;
	double timestampOffset;
	double timestampFactor;

	//*** colors
	Color color_black;
	Color color_grey;
	Color color_light;



	public TimeSeriesView() { 
		this.timeSeries = null;
		this.aggregationInterval = AggregationInterval.HOUR;
		this.viewZoomFactor = 1;
		this.viewOffset = 0;
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

	public void setCanvas(Canvas canvas) {
		this.canvas = canvas;

		color_black = new Color(canvas.getDisplay(),0,0,0);
		color_grey = new Color(canvas.getDisplay(),190,190,190);
		color_light = new Color(canvas.getDisplay(),220,220,220);
	}

	public TimestampSeries getTimeSeries() {
		return timeSeries;
	}

	void updateViewData(TimestampSeries timeSeries, AggregationInterval aggregationInterval) {

		this.timeSeries = timeSeries;
		this.aggregationInterval = aggregationInterval;

		if(timeSeries!=null) {
			updateRangeOfTimeSeriesData();
			updateRangeOfOutputView();
		}	
	}

	void updateRangeOfTimeSeriesData() {
		dataMinValue = Float.MAX_VALUE;
		dataMaxValue = -Float.MAX_VALUE;

		for(TimeSeriesEntry entry:timeSeries) {
			float value = entry.data[0];
			if(!Float.isNaN(value)) {
				if(value<dataMinValue) {
					dataMinValue = value;						
				}
				if(value>dataMaxValue) {
					dataMaxValue = value;						
				}
			}
		}

		dataValueRange = dataMaxValue-dataMinValue;

		dataMinTimestamp = timeSeries.getFirstTimestamp();
		dataMaxTimestamp = timeSeries.getLastTimestamp();
		dataTimestampRange = dataMaxTimestamp-dataMinTimestamp;		
	}

	void updateRangeOfOutputView() {

		minTimestamp = viewOffset+dataMinTimestamp;
		maxTimestamp = viewOffset+dataMinTimestamp+(dataTimestampRange/viewZoomFactor);
		timestampRange = maxTimestamp-minTimestamp;

		minValue = dataMinValue;
		maxValue = dataMaxValue;
		valueRange = maxValue-minValue;

		double scale = (int) (Math.log((dataValueRange))/Math.log(10));
		System.out.println("scale"+scale+" -> "+Math.pow(10, scale));
		float grid = (float) Math.pow(10, scale);

		System.out.println(";"+dataMinValue+" "+dataMaxValue+" "+Math.abs(dataMinValue%grid)+" "+Math.abs(dataMaxValue%grid));

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

		System.out.println(":"+minValue+" "+maxValue);

	}

	void updateRangeOfOutputWindow() {
		xStart = (int) border;
		xEnd = (int)(canvas.getSize().x-border);
		yStart = (int) (canvas.getSize().y-border);
		yEnd = (int) border;

		xRange = xEnd-xStart;
		yRange = yStart-yEnd; //!!		
	}

	void updateDataWindowConversionValues() {
		valueOffset = -minValue;
		valueFactor = yRange/valueRange;
		timestampOffset = -minTimestamp;
		timestampFactor = xRange/(timestampRange+1); //???		
	}


	private void drawGrid(GC gc, double lineStep) {

		Color color_light_blue = new Color(canvas.getDisplay(),220,220,255);

		double firstLine = minValue-minValue%lineStep;
		double maxLines =  (int) ((maxValue-firstLine)/lineStep);


		for(int line=0;line<maxLines;line++) {
			double value = firstLine+line*lineStep;
			int y = valueToGraph(value);

			gc.setForeground(color_light_blue);
			gc.drawLine(xStart , y, xEnd, y);


			//gc.setForeground(color_grey);
			gc.setForeground(color_black);
			gc.drawText(Util.doubleToString(value), 3, y-10);

		}
	}

	private void drawGrid(GC gc) {

		Color color_light_blue = new Color(canvas.getDisplay(),220,220,255);



		int maxLines = (int) (yRange/17);

		double lineStep = valueRange/maxLines;

		System.out.println("lineStep "+lineStep);

		if(lineStep<1) {
			lineStep=1;
		} else if(lineStep<5) {
			lineStep=5;
		} else if(lineStep<10) {
			lineStep=10;
		} else if(lineStep<50) {
			lineStep=50;
		} else if(lineStep<100) {
			lineStep=100;
		} else if(lineStep<500) {
			lineStep=500;
		}

		//drawGrid(gc,lineStep);

		/*final double minLineInterval=17;
		double factor = yRange/valueRange;
		System.out.println("factor: "+factor);
		if(factor>20) {
			lineStep=1;
		} else if(factor>15) {
			lineStep=2;
		} else if(factor>10) {
			lineStep=5;
		} else if(factor>2) {
			lineStep=10;		
		}*/
		
		/*final double minLineInterval=20;
		double minLineValueRange = valueRange/(yRange/minLineInterval);
		System.out.println("valueRange: "+valueRange+"minLineValueRange: "+minLineValueRange);*/


		drawGrid(gc,lineStep);




		LocalDateTime minDateTime = timestampToDataTime(dataMinTimestamp);
		LocalDateTime maxDateTime = timestampToDataTime(dataMaxTimestamp);

		int minYear = minDateTime.getYear();
		int maxYear = maxDateTime.getYear();

		for(int y=minYear;y<=maxYear;y++) {
			long timestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(y, 1, 1, 0, 0));
			if(timestamp>=minTimestamp) {
				int x = (int) (xStart+(timestamp-minTimestamp)*timestampFactor);

				gc.setForeground(color_light_blue);
				gc.drawLine(x , yStart, x, yEnd);

				gc.setForeground(color_black);
				gc.drawText(""+y, x, yStart+20);
			}
			System.out.println(timestamp);
		}


	}

	private int timestampToGraph(double timestamp) {
		//return (int) (xStart+(x*valueFactor));
		//return -1;
		//(int) (offset+border);
		//double offset = (entry.timestamp-minTimestamp)*timestampFactor;
		return (int) (xStart+(timestampOffset+timestamp)*timestampFactor);
	}

	private int valueToGraph(double value) {
		return (int) (yStart-((valueOffset+value)*valueFactor));
	}

	private static LocalDateTime timestampToDataTime(double timestamp) {
		return TimeConverter.oleMinutesToLocalDateTime((long)timestamp);
	}


	private void drawXYAxis(GC gc) {

		gc.setForeground(color_black);

		gc.drawText(""+timestampToDataTime(dataMinTimestamp), xStart, yStart+2);
		gc.drawText(""+timestampToDataTime(dataMaxTimestamp), xEnd-70, yStart+2);

		//gc.drawText(Util.floatToString(minValue), 3, yStart-10);
		//gc.drawText(Util.floatToString(maxValue), 3, yEnd-10);


		gc.setForeground(color_grey);

		gc.drawLine(xStart , yStart, xEnd, yStart); //x-Aches
		gc.drawLine(xStart , yStart, xStart, yEnd); // y-Achse
		gc.drawLine(xStart , yEnd, xEnd, yEnd); //x-Grenze
		gc.drawLine(xEnd , yStart, xEnd, yEnd); // y-Grenze



		//int zero_y = (int) ((height-minValue)*valueFactor+border);


		//  min  zero max

		//  height   * (value-min) 
		//----------------- 
		//(max-min)


		int y = (int) ((yRange-(/*0f-*/minValue)*valueFactor)+border);

		int zero_y = (int) ((int) yRange-(yRange*(/*0-*/minValue)/(maxValue-minValue))+border);
		gc.drawLine(xStart , zero_y, xEnd, zero_y);

		System.out.println(yStart+" "+zero_y+" "+y+" "+yEnd);
	}


	public void paintCanvas(GC gc) {
		if(timeSeries!=null) {



			updateRangeOfOutputWindow();

			updateDataWindowConversionValues();

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
				aggregationTimeInterval=28*24*60;
				break;
			case YEAR:
				aggregationTimeInterval=365*24*60;
				break;
			default:
				System.out.println("error in agg");
			}

			Integer prevX = null;
			Integer prevY = null;

			List<int[]> connectLineList = new ArrayList<int[]>(timeSeries.entryList.size());
			List<int[]> valueLineList = new ArrayList<int[]>(timeSeries.entryList.size());

			for(TimeSeriesEntry entry:timeSeries) {	
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

			drawGrid(gc);

			drawXYAxis(gc);


			gc.setForeground(color_grey);
			for(int[] e:connectLineList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}

			gc.setForeground(color_black);
			for(int[] e:valueLineList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}


			//*** end drawing


			System.out.println("data length: "+timeSeries.entryList.size());
		}

	}

}
