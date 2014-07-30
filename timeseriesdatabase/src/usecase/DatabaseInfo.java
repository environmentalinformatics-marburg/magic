package usecase;

import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.VirtualPlot;
import util.TimestampInterval;

/**
 * print some info of KiLi meta data
 * @author woellauer
 *
 */
public class DatabaseInfo {

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		//timeSeriesDatabase.registerStreams();
		
		
		for(VirtualPlot virtualplot:timeSeriesDatabase.virtualplotMap.values()) {
			System.out.println("******\t"+virtualplot.plotID+"   ("+virtualplot.generalStationName+")\t***");
			for(TimestampInterval<Station> interval:virtualplot.intervalList) {
				String startText = TimeConverter.oleMinutesToText(interval.start);
				String endText = TimeConverter.oleMinutesToText(interval.end);
				String typeText = util.Util.ifnull(interval.value.getLoggerType(), x->x.typeName, ()->"unknown");
				System.out.println(startText+" - "+endText+"\t\tstream name: "+interval.value.plotID+"\t"+typeText);
			}
			System.out.println();
			System.out.println();
			virtualplot.getStationList(null, null, null);
			System.out.println();
			System.out.println();
		}
		
		
	}

}
