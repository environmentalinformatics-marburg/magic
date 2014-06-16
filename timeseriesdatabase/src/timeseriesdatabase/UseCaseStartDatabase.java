package timeseriesdatabase;

import java.io.IOException;
import java.nio.file.Paths;
import java.util.Iterator;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import de.umr.eventstore.Stream;
import de.umr.eventstore.processors.CSVProcessor;
import de.umr.eventstore.processors.ConsoleProcessor;
import de.umr.eventstore.processors.ProcessingEngine;
import de.umr.eventstore.processors.Processor;
import de.umr.eventstore.queries.Query;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.eventstore.storage.Schema;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;

/**
 * UseCaseStartDatabase opens an existing database and processes some queries.
 * @author Stephan Wöllauer
 *
 */
public class UseCaseStartDatabase {
	
	private static final Logger log = Util.log;

	public static void main(String[] args) {
		System.out.println("begin...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();		
		
		Attribute[] schema = timeSeriesDatabase.stationMap.get("HEG03").getLoggerType()._schema;
		String attrs="tstart";
		for(Attribute attribute:schema) {
			attrs+=","+attribute.getAttributeName();
		}
		
		String sql = "SELECT "+attrs+" FROM HEG03";
		//String sql = "SELECT tstart, Ta_10, Ts_10 FROM HEG03";
		//String sql = "SELECT tstart, Ta_10, Ts_10 FROM HEG03 WHERE tstart>=0 AND tstart<=57401280";
		//String sql = "SELECT tstart, Ta_10, Ts_10 FROM HEG03 WHERE tstart>=58508670 AND tstart<=58508690";
		//String sql = "SELECT Ta_10, Ts_10 FROM HEG03 WHERE tstart=58508670";
		System.out.println("\n"+sql);
		
		Stream stream = timeSeriesDatabase.store.getStream("HEG03");
		
		ProcessingEngine engine = new ProcessingEngine(stream);
        //engine.appendProcessor(new ConsoleProcessor());
        try {
			engine.appendProcessor(new CSVProcessor("k:/output/result.csv"," "));
		} catch (IOException e) {
			e.printStackTrace();
		}
        
        
        engine.appendProcessor(new Processor() {
        	
        	Event prevEvent = null;
        	long counter = 0;
			
			@Override
			public void process(Event e) {
				if(prevEvent!=null) {
					long prevTimestamp = prevEvent.getTimestamp();
					long currTimestamp = e.getTimestamp();
					long diff = currTimestamp-prevTimestamp;
					if(diff<=0) {
						System.out.println(counter+"\tdiff:\t"+TimeConverter.minutesToDuration(diff)+"\tat\t"+currTimestamp+"\t"+TimeConverter.oleMinutesToLocalDateTime(currTimestamp));
					}
				}
				prevEvent = e;
				counter++;
			}
			
			@Override
			public void init(Schema s) {
				// TODO Auto-generated method stub
				
			}
			
			@Override
			public void close() {
				// TODO Auto-generated method stub
				
			}
		});
        
        
        /* Create an SQL query */
        Query query = new SQLQuery(sql);

        /* Query the stream with the processing engine */
        engine.processQuery(query);
		
		
		
		/*
		Iterator<Event> it = timeSeriesDatabase.query(sql);
		while(it.hasNext()) {
			Event next = it.next();
			System.out.println(next);
		}
		*/
		
		
		
		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);

	}

}
