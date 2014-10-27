package tsdb.gui.util;

import java.time.LocalDateTime;
import java.util.Calendar;
import java.util.GregorianCalendar;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.widgets.Display;

import tsdb.TimeConverter;
import tsdb.gui.util.Painter.PosHorizontal;
import tsdb.gui.util.Painter.PosVerical;

public class TimeScalePainter {	
	Color color_light_blue;
	Color color_year;
	Color color_half_year;
	Color color_year_text;
	Color color_half_year_text;
	Color color_quarter_year_text;

	double minTimestamp;
	double maxTimestamp;
	double timestampFactor;

	int xStart;
	int xEnd;
	int yStart;
	int yEnd;
	int y;

	public void setColor(Display display) {
		color_light_blue = new Color(display,220,220,255);
		color_year = new Color(display,220-50,220-50,255-50);
		color_half_year = new Color(display,220-30,220-30,255-30);

		color_year_text = new Color(display,0,0,0);
		color_half_year_text = new Color(display,100,100,100);
		color_quarter_year_text = new Color(display,150,150,150);		
	}

	private void drawMark(GC gc,Color lineColor, Color textColor, String text,int year,int month,int day,int hour) {
		long timestamp = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(year, month, day, hour, 0));
		int x = timestampToGraph(timestamp);
		gc.setForeground(lineColor);
		gc.drawLine(x , yStart, x, yEnd);
		gc.setForeground(textColor);
		Painter.drawText(text,gc, x, y,PosHorizontal.CENTER,PosVerical.TOP);
	}

	public void paint(GC gc, double minTimestamp, double maxTimestamp,int xStart,int xEnd,int yStart,int yEnd,int y) {
		this.xStart = xStart;
		this.xEnd = xEnd;
		this.yStart = yStart;
		this.yEnd = yEnd;
		this.y = y;
		this.minTimestamp = minTimestamp;
		this.maxTimestamp = maxTimestamp;
		this.timestampFactor = (xEnd-xStart)/(maxTimestamp-minTimestamp);

		final int minGap = 25;

		//gc.setClipping(xStart, y, width, height);



		LocalDateTime minDateTime = timestampToDataTime(minTimestamp);
		LocalDateTime maxDateTime = timestampToDataTime(maxTimestamp);


		int yearStep = timestampToGraph(TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2001, 1, 1, 0, 0)))-timestampToGraph(TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2000, 1, 1, 0, 0)));




		int minYear = minDateTime.getYear();
		int maxYear = maxDateTime.getYear();

		int year = minYear-1;

		while(year<=maxYear) {			
			drawMark(gc,color_year,color_year_text,""+year,year,1,1,0);
			year++;
			if(yearStep/2>=minGap) {				
				drawMark(gc,color_half_year,color_half_year_text,"jul",year,7,1,0);
				if(yearStep/4>=minGap) {				
					drawMark(gc,color_light_blue,color_quarter_year_text,"apr",year,4,1,0);
					drawMark(gc,color_light_blue,color_quarter_year_text,"oct",year,10,1,0);
					if(yearStep/12>=minGap) {				
						drawMark(gc,color_light_blue,color_light_blue,"feb",year,2,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"mar",year,3,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"may",year,5,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"jun",year,6,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"aug",year,8,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"sep",year,9,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"nov",year,11,1,0);
						drawMark(gc,color_light_blue,color_light_blue,"dec",year,12,1,0);


						if(yearStep/(12*30)>=minGap) {
							for(int month=1;month<=12;month++) {
								int maxDays = new GregorianCalendar(year, month-1, 1).getActualMaximum(Calendar.DAY_OF_MONTH);
								//System.out.println("maxDays: "+maxDays+"   "+year+"  "+month);
								for(int i=2;i<=maxDays;i++) {
									drawMark(gc,color_light_blue,color_light_blue,""+i+".",year,month,i,0);
								}
								if(yearStep/(12*30*24)>=minGap) {
									for(int day=1;day<=maxDays;day++) {										
										for(int h=1;h<24;h++) {										
											drawMark(gc,color_light_blue,color_light_blue,""+h+"h",year,month,day,h);
										}
									}
								} else if(yearStep/(12*30*8)>=minGap) {
									for(int day=1;day<=maxDays;day++) {								
										drawMark(gc,color_light_blue,color_light_blue,""+3+"h",year,month,day,3);
										drawMark(gc,color_light_blue,color_light_blue,""+6+"h",year,month,day,6);
										drawMark(gc,color_light_blue,color_light_blue,""+9+"h",year,month,day,9);
										drawMark(gc,color_light_blue,color_light_blue,""+12+"h",year,month,day,12);
										drawMark(gc,color_light_blue,color_light_blue,""+15+"h",year,month,day,15);
										drawMark(gc,color_light_blue,color_light_blue,""+18+"h",year,month,day,18);
										drawMark(gc,color_light_blue,color_light_blue,""+21+"h",year,month,day,21);
									}
								} else if(yearStep/(12*30*4)>=minGap) {
									for(int day=1;day<=maxDays;day++) {								
										drawMark(gc,color_light_blue,color_light_blue,""+6+"h",year,month,day,6);
										drawMark(gc,color_light_blue,color_light_blue,""+12+"h",year,month,day,12);
										drawMark(gc,color_light_blue,color_light_blue,""+18+"h",year,month,day,18);
									}
								} else if(yearStep/(12*30*2)>=minGap) {
									for(int day=1;day<=maxDays;day++) {								
										drawMark(gc,color_light_blue,color_light_blue,""+12+"h",year,month,day,12);
									}
								}
							}
						} else if(yearStep/(12*4)>=minGap) {
							for(int month=1;month<=12;month++) {
								int maxDays = new GregorianCalendar(year, month-1, 1).getActualMaximum(Calendar.DAY_OF_MONTH);
								int half1 = maxDays/4+1;
								drawMark(gc,color_light_blue,color_light_blue,""+half1+".",year,month,half1,0);
								int half = maxDays/2+1;
								drawMark(gc,color_light_blue,color_light_blue,""+half+".",year,month,half,0);
								int half2 = (maxDays*3)/4+1;
								drawMark(gc,color_light_blue,color_light_blue,""+half2+".",year,month,half2,0);
							}
						} else if(yearStep/(12*2)>=minGap) {
							for(int month=1;month<=12;month++) {
								int maxDays = new GregorianCalendar(year, month-1, 1).getActualMaximum(Calendar.DAY_OF_MONTH);
								int half = maxDays/2+1; 
								drawMark(gc,color_light_blue,color_light_blue,""+half+".",year,month,half,0);
							}
						}
					}
				}
			}
		}
	}

	private static LocalDateTime timestampToDataTime(double timestamp) {
		return TimeConverter.oleMinutesToLocalDateTime((long)timestamp);
	}

	private int timestampToGraph(double timestamp) {
		return (int) (xStart + (timestamp-minTimestamp)*timestampFactor);
	}

}
