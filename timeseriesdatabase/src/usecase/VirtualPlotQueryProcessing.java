package usecase;

import java.util.ArrayList;
import java.util.List;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.iterator.VirtualPlotIterator;
import timeseriesdatabase.raw.TimeSeriesEntry;
import timeseriesdatabase.raw.TimestampSeries;
import util.Builder;
import util.TimestampInterval;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class VirtualPlotQueryProcessing {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	public static void main(String[] args) {
		System.out.println("start...");
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);


		//Builder.base_aggregated(qp, "51021020164", null, null, null, DataQuality.NO).writeCSV(CSV_OUTPUT_PATH+"kili_51021020164.csv");


		String plotName = "cof3";
		Long queryStart = null;
		Long queryEnd = null;
		String[] schema = null;
		
		DataQuality dataQuality = DataQuality.EMPIRICAL;
		boolean interpolated = false;
		qp.virtualquery_aggregated(plotName, schema, queryStart, queryEnd, dataQuality , AggregationInterval.HOUR, interpolated).writeCSV(CSV_OUTPUT_PATH+"virtualPlot.csv");;
		
		/*
		VirtualPlot virtualPlot = timeSeriesDatabase.virtualplotMap.get(plotName);

		
		List<TimestampInterval<Station>> intervalList = virtualPlot.getStationList(queryStart, queryEnd, schema);
		System.out.println("\nplotID: "+plotName);
		System.out.println(Util.arrayToString(virtualPlot.getSchema()));
		
		List<TimeSeriesIterator> processing_iteratorList = new ArrayList<TimeSeriesIterator>();
		
		for(TimestampInterval<Station> interval:intervalList) {
			System.out.println(interval+" "+interval.value.loggerType.typeName+":\t\t\t"+Util.arrayToString(interval.value.loggerType.sensorNames));			
			TimeSeriesIterator it = Builder.base_aggregated(qp, interval.value.plotID, null, interval.start, interval.end, DataQuality.NO).create();			
			if(it!=null&&it.hasNext()) {
				processing_iteratorList.add(it);
			}
		}
		
		System.out.println("\nprocessing_iterators: "+processing_iteratorList.size()+"\n");
		
		String[] result_schema = timeSeriesDatabase.getBaseAggregationSchema(virtualPlot.getSchema());
		
		VirtualPlotIterator it = new VirtualPlotIterator(result_schema, processing_iteratorList.toArray(new TimeSeriesIterator[0]));
		
		it.writeCSV(CSV_OUTPUT_PATH+"virtualPlot.csv");*/
		
		/*

		
		
		TimeSeriesIterator[] processing_iterator = processing_iteratorList.toArray(new TimeSeriesIterator[0]);
		TimeSeriesEntry[] processing_current = new TimeSeriesEntry[processing_iterator.length];
		int[][] processing_position_index = new int[processing_iterator.length][];
		
		for(int iterator_index=0;iterator_index<processing_iterator.length;iterator_index++) {
			processing_position_index[iterator_index] = Util.stringArrayToPositionIndexArray(processing_iterator[0].getOutputSchema(), result_schema, true, true);
		}

		
		long currentTimestamp=Long.MAX_VALUE;
		for(int iterator_index=0;iterator_index<processing_iterator.length;iterator_index++) {
			processing_current[iterator_index] = processing_iterator[iterator_index].next();
			if(processing_current[iterator_index].timestamp<currentTimestamp) {
				currentTimestamp = processing_current[iterator_index].timestamp; // set start timestamp
			}
		}
		
		//one element in every entry in current
		int currentElements = processing_iterator.length;
		
		while(currentElements>0) {
			float[] resultData = new float[result_schema.length];
			for(int iterator_index=0;iterator_index<processing_iterator.length;iterator_index++) {
				if(processing_current[iterator_index]!=null) {
					if(processing_current[iterator_index].timestamp == currentTimestamp) { // insert data into resultData
						float[] data = processing_current[iterator_index].data;
						for(int colIndex=0;colIndex<data.length;colIndex++) {
							if(!Float.isNaN(data[colIndex])) {
								resultData[processing_position_index[iterator_index][colIndex]] = data[colIndex];
							}
						}
						if(processing_iterator[iterator_index].hasNext()) {
							processing_current[iterator_index] = processing_iterator[iterator_index].next(); 
						} else {
							processing_current[iterator_index] = null;
							currentElements--;
						}
					}
				}
			}
			//output result element
			TimeSeriesEntry resultTimeSeriesEntry = new TimeSeriesEntry(currentTimestamp, resultData);
			System.out.println(resultTimeSeriesEntry);
			
			//set next element timestamp
			currentTimestamp=Long.MAX_VALUE;
			for(int iterator_index=0;iterator_index<processing_iterator.length;iterator_index++) {
				processing_current[iterator_index] = processing_iterator[iterator_index].next();
				if(processing_current[iterator_index]!=null && processing_current[iterator_index].timestamp<currentTimestamp) {
					currentTimestamp = processing_current[iterator_index].timestamp; // set start timestamp
				}
			}
		}

		*/
		





		System.out.println("\n...end");
	}

}
