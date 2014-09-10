package tsdb.usecase;

import java.io.IOException;
import java.time.LocalDateTime;

import tsdb.TimeConverter;
import tsdb.graph.Base;
import tsdb.graph.CSVSource;
import tsdb.graph.Continuous;
import tsdb.graph.Node;
import tsdb.graph.PeakSmoothed;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.iterator.CSVIterator;
import tsdb.util.iterator.TimeSeriesIterator;

public class Tfi_csv {

	public static void main(String[] args) throws IOException {
		
		
		String filename = "C:/timeseriesdatabase_output/kili_tfi/fer0_tfi_changed.csv";
		
		/*
		Table table = Table.readCSV(filename, ',');
		
		System.out.println("header: "+Util.arrayToString(table.names));
		
		for(String[] row:table.rows) {
			System.out.println("row: "+Util.arrayToString(row));
			
			System.out.println("date time "+row[0]+row[1]);
			
			for(int i=2;i<row.length;i++) {
				try {
				System.out.println(Float.parseFloat(row[i]));
				} catch (Exception e) {
					System.out.println("**************************   "+row[i]+"   ***************************************");
				}
			}
			
			//Float.parseFloat(s);
		}*/
		
		//CSVIterator it = CSVIterator.create(filename);
		
		Node source= CSVSource.create(filename);
		Base base = PeakSmoothed.create(source);
		Continuous continuous = Continuous.create(base);
		
		//TimeSeriesIterator it = base.get(null, null);
		TimeSeriesIterator it = continuous.get(null, null);
		
		while(it.hasNext()) {
			TimeSeriesEntry e = it.next();
			System.out.println(e);
		}
		
		//Long queryStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2012,11,7,9,20,00));
		//Long queryEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2014,8,6,12,22,00));
		Long queryStart = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2012,11,01,03,20,00));
		Long queryEnd = TimeConverter.DateTimeToOleMinutes(LocalDateTime.of(2014,8,8,8,25,00));
		
		continuous.getExactly(queryStart, queryEnd).writeCSV("c:/timeseriesdatabase_output/Manual_B_new.csv");
		

	}

}
