package tsdb.usecase;

import java.util.Iterator;
import java.util.List;
import java.util.stream.Stream;

import tsdb.DataQuality;
import tsdb.FactoryTsDB;
import tsdb.QueryProcessor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.iterator.EmpiricalIterator_OLD;
import tsdb.util.CSV;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class TestingEmpiricalIterator {
	
	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";
	
	private static final int NEAR_STATIONS = 3;

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);
		
		String basePlotID = "HEW08";
		String sensorName = "Ts_5";
		String[] querySchema = new String[]{sensorName};
		Long queryStart = 56936340l;
		Long queryEnd = 59809800l;
		DataQuality dataQuality = DataQuality.PHYSICAL;
		
		Station station = timeSeriesDatabase.getStation(basePlotID);
		
		List<Station> nearList = station.getNearestStationsWithSensor("Ta_200");
		
		Stream<Station> stream = nearList.stream();
		Stream<TimeSeriesIterator> stream1 = stream.map(x->qp.query_continuous_base_aggregated(x.stationID, querySchema, queryStart, queryEnd, dataQuality));
		Iterator<TimeSeriesIterator> it = stream1.iterator();

		TimeSeriesIterator[] itNear = new TimeSeriesIterator[NEAR_STATIONS];
		int c = Util.fillArray(nearList, itNear, x->qp.query_continuous_base_aggregated(x.stationID, querySchema, queryStart, queryEnd, dataQuality));
		if(c<NEAR_STATIONS) {
			throw new RuntimeException("c: "+c+" "+nearList.size());
		}
		
		TimeSeriesIterator itBase = qp.query_continuous_base_aggregated(basePlotID, querySchema, queryStart, queryEnd, dataQuality);
		
		
		
		Float[] maxDiff = new Float[]{/*0.79f*/1.514f};
		EmpiricalIterator_OLD resultIterator = new EmpiricalIterator_OLD(itBase, itNear, maxDiff);
		
		CSV.write(resultIterator, CSV_OUTPUT_PATH+"testing_empirical_diff.csv");
		
		itBase = qp.query_continuous_base_aggregated(basePlotID, querySchema, queryStart, queryEnd, dataQuality);
		CSV.write(itBase, CSV_OUTPUT_PATH+"testing_empirical_diff_original.csv");
		
		
		
		System.out.println("...end");
	}

}
