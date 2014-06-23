package usecase;

import java.io.IOException;
import java.time.LocalDateTime;

import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import de.umr.eventstore.Stream;
import de.umr.eventstore.processors.CSVProcessor;
import de.umr.eventstore.processors.ProcessingEngine;
import de.umr.eventstore.processors.Processor;
import de.umr.eventstore.queries.Query;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.eventstore.storage.Schema;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

public class UseCaseQueryOneTimeSeries {
	public static void main(String[] args) {
		
		
		//String sql = "SELECT * FROM HEG01 WHERE tstart>="+timeStart+" AND tstart<="+timeEnd;
		//String plotID = "HEG25";
		String plotID = "HEW01";
		String sql = "SELECT tstart, Ta_10 FROM "+plotID;
		System.out.println(sql);
		
		
		System.out.println("begin...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();		
		Stream stream = timeSeriesDatabase.store.getStream(plotID);		
		Schema<? extends Attribute> schema = stream.getSchema();
		System.out.println("*** schema ***");
		System.out.println(schema);
		System.out.println("***");
		
		ProcessingEngine engine = new ProcessingEngine(stream);
		engine.appendProcessor(new Processor() {
			
			Long lastTimeStamp=null;
			
			@Override
			public void process(Event e) {
				long timestamp = e.getTimestamp();
				float value = (Float) e.getPayload()[1];
				if(!Float.isNaN(value)&&lastTimeStamp!=null) {
					long timespan = timestamp-lastTimeStamp;
					if(timespan<0||(timespan!=30&&timespan!=10&&timespan!=60&&timespan!=20)) {
						System.out.println(timestamp+"\t"+TimeConverter.oleMinutesToLocalDateTime(timestamp)+"\ttimespan: "+timespan+"\t"+e);
					}
					//System.out.println(TimeConverter.oleMinutesToLocalDateTime(timestamp)+"\ttimespan: "+timespan);
					//System.out.println(e);
				}
				lastTimeStamp = timestamp;
			}
			
			@Override
			public void init(Schema s) {}
			
			@Override
			public void close() {}
		});
		
		try {
			engine.appendProcessor(new CSVProcessor("k:/output/result.csv"," "));
		} catch (IOException e1) {
			e1.printStackTrace();
		}
		
		//long timeStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2011,03,01,05,00));
		//long timeEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2011,03,01,18,0));
		
		long timeStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2013,03,01,05,00));
		long timeEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2013,03,01,18,0));
		
		
		Query query = new SQLQuery(sql);
        engine.processQuery(query);
		

		
		
		System.out.println("...end");

	}
}
