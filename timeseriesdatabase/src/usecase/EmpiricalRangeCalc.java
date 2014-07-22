package usecase;

import java.util.List;
import java.util.TreeSet;
import java.util.function.Consumer;

import javax.xml.ws.spi.Invoker;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import util.CSV;
import util.CSVTimeType;
import util.iterator.TimeSeriesIterator;
import util.iterator.TimeSeriesIteratorIterator;
import timeseriesdatabase.aggregated.iterator.NanRemoveIterator;

public class EmpiricalRangeCalc {
	
	private static final int NEAR_STATIONS = 3;

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);


		//String plotID = "HEG01";
		//String plotID = "HEG20";
		//String plotID = "HEW12";
		//String[] querySchema = new String[]{"Ta_200"};
		String[] querySchema = new String[]{"Ta_200","rH_200","Ta_10","Ts_5","Ts_10","Ts_20","Ts_50","SM_10","SM_15","SM_20"};
		//String[] querySchema = null;
		Long queryStart = null;
		Long queryEnd = null;


		String[] generalStationNames = new String[]{"HEG","HEW"};

		for(String generalStationName:generalStationNames) {

			GeneralStation generalStation = timeSeriesDatabase.generalStationMap.get(generalStationName);
			List<Station> stationList = generalStation.stationList;
			
			//TimeSeriesIterator it = TimeSeriesIteratorIterator.create(stationList, station -> new NanRemoveIterator(qp.queryRawQualityChecked(station.plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange)));
			TimeSeriesIterator it = TimeSeriesIteratorIterator.create(stationList, station -> new NanRemoveIterator(qp.query_raw_with_bad_quality_removed(station.plotID, querySchema, queryStart, queryEnd, DataQuality.STEP)));
			
			//TimeSeriesIterator it = qp.queryRaw(plotID, querySchema, queryStart, queryEnd);		
			//TimeSeriesIterator it = qp.queryQualityChecked(plotID, querySchema, queryStart, queryEnd, checkPhysicalRange, checkEmpiricalRange, checkStepRange);
			//TimeSeriesIterator it = qp.queryAggregated(plotID, querySchema, start, end, AggregationInterval.DAY, false, false, false, false);
			CSV.writeNoHeader(it, "c:/timeseriesdatabase_output/empirical_range_"+generalStationName+".csv", ",", "?", CSVTimeType.TIMESTAMP);


		}

		


		System.out.println("...end");
	}

}
