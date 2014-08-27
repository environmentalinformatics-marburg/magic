package tsdb.usecase;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

import tsdb.DataQuality;
import tsdb.FactoryTsDB;
import tsdb.QueryProcessor;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.raw.TimestampSeries;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import de.umr.eventstore.Stream;
import de.umr.eventstore.processors.CSVProcessor;
import de.umr.eventstore.processors.ProcessingEngine;
import de.umr.eventstore.processors.Processor;
import de.umr.eventstore.queries.Query;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.eventstore.storage.Schema;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

/**
 * use case for base aggregation
 * @author woellauer
 *
 */
public class UseCaseBaseAggregation {

	public static void main(String[] args) {
		System.out.println("begin...");
		
		System.out.println("start database...");

		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		System.out.println("query data...");
		
		String plotID = "HEG31";
		//String plotID = "HEG25";
		LocalDateTime start = LocalDateTime.of(2013,01,01,0,0);
		LocalDateTime end = LocalDateTime.of(2013,01,31,23,59);
		long startTimestamp = TimeConverter.DateTimeToOleMinutes(start);
		long endTimestamp = TimeConverter.DateTimeToOleMinutes(end);
		//String[] queryParameterNames = new String[] {"Ta_200","WD","WV"};
		//String[] queryParameterNames = new String[] {"Ta_200"};
		String[] queryParameterNames = null;
		
		TimestampSeries timeSeries = TimestampSeries.create(qp.query_base_aggregated(plotID, queryParameterNames, null, null, DataQuality.NO));


		
		System.out.println("print part of timeseries...");

		System.out.println(timeSeries);
		
		System.out.println("write data to file...");

		CSV.write(timeSeries,"c:/timeseriesdatabase_output/result.csv", " ", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);		
		
		System.out.println("...end");

		//timeSeriesDatabase.close();

	}

}