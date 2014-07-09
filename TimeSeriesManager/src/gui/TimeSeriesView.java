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
	double timeOffset;
	double timeFactor;

	//*** colors
	Color color_black;
	Color color_grey;
	Color color_light;



	public TimeSeriesView() { 
		this.timeSeries = null;
		this.aggregationInterval = AggregationInterval.HOUR;
	}

	public void setCanvas(Canvas canvas) {
		this.canvas = canvas;
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

		double scale = (int) (Math.log((dataMaxValue-dataMinValue))/Math.log(10));
		System.out.println("scale"+scale+" -> "+Math.pow(10, scale));
		float grid = (float) Math.pow(10, scale);

		System.out.println(";"+dataMinValue+" "+dataMaxValue+" "+Math.abs(dataMinValue%grid)+" "+Math.abs(dataMaxValue%grid));

		double absRestMin = Math.abs(dataMinValue%grid);
		if(dataMinValue>0) {
			dataMinValue = dataMinValue-absRestMin;
		} else {
			if(absRestMin>0) {
				dataMinValue = dataMinValue-(grid-absRestMin);
			}
		}

		double absRestMax = Math.abs(dataMaxValue%grid);
		if(absRestMax>0) {
			if(absRestMax>0) {
				dataMaxValue = dataMaxValue+(grid-absRestMax);
			}
		} else {
			dataMaxValue = dataMaxValue+absRestMax;
		}
		
		timestampRange = dataMaxTimestamp-dataMinTimestamp;
		valueRange = dataMaxValue-dataMinValue;

		System.out.println(":"+dataMinValue+" "+dataMaxValue);

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
		valueFactor = yRange/(dataMaxValue-dataMinValue);
		valueOffset = -dataMinValue;
		timeFactor = xRange/(dataTimestampRange+1); //???		
	}



	



	private void drawGrid(GC gc) {

		gc.setForeground(color_light);

		double graphYDiff = yStart-yEnd;
		double valueDiff = dataMaxValue-dataMinValue;

		int maxLines = (int) (graphYDiff/17);


		double lineStep = valueDiff/maxLines;

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

		double firstLine = dataMinValue-dataMinValue%lineStep;
		maxLines =  (int) ((dataMaxValue-firstLine)/lineStep);


		for(int line=0;line<maxLines;line++) {
			double value = firstLine+line*lineStep;
			int y = valueToGraph(value);

			gc.setForeground(color_light);
			gc.drawLine(xStart , y, xEnd, y);


			//gc.setForeground(color_grey);
			gc.setForeground(color_black);
			gc.drawText(Util.doubleToString(value), 3, y-10);

		}


		LocalDateTime minDateTime = timestampToDataTime(dataMinTimestamp);
		LocalDateTime maxDateTime = timestampToDataTime(dataMaxTimestamp);

		int minYear = minDateTime.getYear();
		int maxYear = maxDateTime.getYear();

		for(int y=minYear;y<=maxYear;y++) {
			long timestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(y, 1, 1, 0, 0));
			if(timestamp>=dataMinTimestamp) {
				int x = (int) (xStart+(timestamp-dataMinTimestamp)*timeFactor);

				gc.setForeground(color_light);
				gc.drawLine(x , yStart, x, yEnd);

				gc.setForeground(color_black);
				gc.drawText(""+y, x, yStart+20);
			}
			System.out.println(timestamp);
		}


	}

	private int timestampToGraph(long timestamp) {
		//return (int) (xStart+(x*valueFactor));
		return -1;
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


		int y = (int) ((yRange-(/*0f-*/dataMinValue)*valueFactor)+border);

		int zero_y = (int) ((int) yRange-(yRange*(/*0-*/dataMinValue)/(dataMaxValue-dataMinValue))+border);
		gc.drawLine(xStart , zero_y, xEnd, zero_y);

		System.out.println(yStart+" "+zero_y+" "+y+" "+yEnd);





	}


	public void paintCanvas(GC gc) {
		if(timeSeries!=null) {

			color_black = new Color(canvas.getDisplay(),0,0,0);
			color_grey = new Color(canvas.getDisplay(),190,190,190);
			color_light = new Color(canvas.getDisplay(),220,220,220);
			
			updateRangeOfOutputWindow();

			updateDataWindowConversionValues();

			









			int agg = 60;
			switch(aggregationInterval) {
			case HOUR:
				agg=60;
				break;
			case DAY:
				agg=1*24*60;
				break;
			case WEEK:
				agg=7*24*60;
				break;
			case MONTH:
				agg=28*24*60;
				break;
			case YEAR:
				agg=365*24*60;
				break;
			default:
				System.out.println("error in agg");
			}


			double timeAggregationSize = agg*timeFactor;


			System.out.println("valueFactor: "+valueFactor);
			System.out.println("valueOffset: "+valueOffset);

			Float prevValue = null;

			//for(int offset=0;offset<data.length;offset++) {
			/*for(TimestampSeriesEntry entry:resultTimeSeries) {	
				float value = entry.data[0];
				long offset = entry.timestamp-minTimestamp;
				if(!Float.isNaN(value)) {
					int x = (int) (offset*timeFactor);
					int y = (int)(height-((value+valueOffset)*valueFactor));
					if(prevValue!=null) {
						int xprev = (int) ((offset-1)*timeFactor);
						int yprev = (int)(height-((prevValue+valueOffset)*valueFactor));
						gc.drawLine(xprev, yprev, x, y);
					} else {
						gc.drawLine(x, y, x, y);
					}
					prevValue = value;
				} else {
					prevValue = null;
				}
			}*/

			//Color white = display.getSystemColor(SWT.COLOR_WHITE);
			//Color black = display.getSystemColor(SWT.COLOR_BLACK);



			Integer prevX = null;
			Integer prevY = null;

			List<int[]> grayList = new ArrayList<int[]>(timeSeries.entryList.size());
			List<int[]> blackList = new ArrayList<int[]>(timeSeries.entryList.size());

			for(TimeSeriesEntry entry:timeSeries) {	
				float value = entry.data[0];
				if(!Float.isNaN(value)) {				
					double offset = (entry.timestamp-dataMinTimestamp)*timeFactor;
					int x0 = (int) (offset+border);
					int x1 = (int) (offset+timeAggregationSize+border);
					int y = (int) ((yRange-(value-dataMinValue)*valueFactor)+border);
					if(prevX!=null) {
						//gc.setForeground(c1);
						//gc.drawLine(x0, prevY, x0, y);
						grayList.add(new int[]{x0, prevY, x0, y});
					}
					//gc.setForeground(c0);
					//gc.drawLine(x0, y, x1, y);
					blackList.add(new int[]{x0, y, x1, y});
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
			for(int[] e:grayList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}

			gc.setForeground(color_black);
			for(int[] e:blackList) {
				gc.drawLine(e[0], e[1], e[2], e[3]);
			}


			//*** end drawing


			System.out.println("data length: "+timeSeries.entryList.size());
		}

	}

}
