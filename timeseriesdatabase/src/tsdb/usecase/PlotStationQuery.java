package tsdb.usecase;

import java.util.Arrays;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.VirtualPlot;
import tsdb.graph.VirtualPlotStationRawSource;
import tsdb.raw.TimestampSeries;
import tsdb.util.TimestampInterval;
import tsdb.util.iterator.TsIterator;

public class PlotStationQuery {

	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();
		
		
		String plotID = "cof3";
		String stationID = "80091030030";
		String[] querySchema = new String[]{"Ta_200","Ts_10"};
		//String[] querySchema = null;
		
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);		
		
		for(TimestampInterval<StationProperties> interval:virtualPlot.intervalList) {
			String stationName = interval.value.get_serial(); 
			Station station = tsdb.getStation(interval.value.get_serial());			
			String[] sensorNames = tsdb.streamStorage.getSensorNames(stationName);
			System.out.println(stationName+"   "+Arrays.toString(sensorNames)+"   "+interval);
			//StreamIterator it = tsdb.streamStorage.getRawSensorIterator(stationName, sensorNames[0], interval.start, interval.end);
			TsIterator it = tsdb.streamStorage.getRawIterator(stationName, sensorNames, interval.start, interval.end);
			
			TimestampSeries tss = it.toTimestampSeries(plotID+":"+stationName);
			System.out.println(tss);

		}
		
		VirtualPlotStationRawSource node = VirtualPlotStationRawSource.of(tsdb, plotID, stationID, querySchema);
		TsIterator it = node.get(null, null);
		TimestampSeries tss = it.toTimestampSeries(plotID+":"+stationID);
		System.out.println(tss);
		
		
		
		tsdb.close();

	}

}
