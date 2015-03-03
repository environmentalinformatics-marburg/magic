package tsdb.usecase;

import java.rmi.RemoteException;

import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.streamdb.DataEntry;
import tsdb.streamdb.StreamIterator;

public class StationRawQuery {

	public static void main(String[] args) throws RemoteException {
		
		
		String stationName = "51021020218";
		String sensorName = "Ta_200";
		String[] sensorNames = new String[]{sensorName};
		
		TsDB tsdb = TsDBFactory.createDefault();
		
		//Long start = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2014,8,1,0,0));
		//Long end = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2014,8,31,23,0));
		Long start = TimeConverter.getYearStartTimestamp(2014);
		Long end = TimeConverter.getYearEndTimestamp(2014);
		//Long start = null;
		//Long end = null;
		StreamIterator it = tsdb.streamStorage.getRawSensorIterator(stationName, "Ta_200", start, end);
		while(it.hasNext()) {
			DataEntry e = it.next();
			//System.out.println(e);
		}		
		
		
		//TsIterator it = tsdb.streamStorage.getRawIterator(stationName, sensorNames, start, end, null);
		//it.writeCSV(TsDBFactory.OUTPUT_PATH+"/"+"station.csv");
		/*while(it.hasNext()) {
			TsEntry e = it.next();
			System.out.println(e);
		}*/
		
		
		
		/*ServerTsDB serverTsdb = new ServerTsDB(tsdb);
		
		TimestampSeries ts = serverTsdb.plot(null, "cof1", sensorNames, AggregationInterval.HOUR, DataQuality.NO, false, start, end);
		TsIterator it = ts.tsIterator();
		while(it.hasNext()) {
			TsEntry e = it.next();
			System.out.println(e);
		}*/
		
		//Node node = QueryPlan.plot(tsdb, "cof1", sensorNames, AggregationInterval.HOUR, DataQuality.NO, false);
		//Node node = StationRawSource.of(tsdb, stationName, sensorNames);
		//Node node = VirtualRawSource.of(tsdb, tsdb.getVirtualPlot("cof1"), sensorNames);		
		
		//NodeGen stationGen = QueryPlan.getStationGen(tsdb, DataQuality.NO);		
		//Base node = Base.of(tsdb, "cof1", sensorNames, stationGen);
		//Node node = StationBase.of(tsdb, tsdb.getStation(stationName), sensorNames, stationGen);
		//Node node = stationGen.get(stationName, sensorNames);
				
		//TsIterator it = node.get(start, end);
		//TsIterator it = node.get(null, null);
		
		//it.writeCSV(TsDBFactory.OUTPUT_PATH+"/"+"station.csv");
		
		//it = new BaseAggregationIterator(tsdb,it);
		
		/*
		while(it.hasNext()) {
			TsEntry e = it.next();
			System.out.println(e);
		}
		*/
		
		tsdb.close();
		

	}

}
