package tsdb.run;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.raw.TimestampSeries;
import tsdb.raw.TsEntry;
import tsdb.util.Table;
import tsdb.util.Table.ColumnReaderFloat;
import tsdb.util.Table.ColumnReaderSlashTimestamp;
import tsdb.util.Table.ColumnReaderString;
import tsdb.util.Util;

public class SouthAfricaPreImport_saws_acs {
	
	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) {
		System.out.println("start...");
		
		try {
			//DirectoryStream<Path> ds = Files.newDirectoryStream(Paths.get("C:/timeseriesdatabase_source/sa/TESTING"));
			DirectoryStream<Path> ds = Files.newDirectoryStream(Paths.get(TsDBFactory.OUTPUT_PATH+"/sa/SAWS/ACS"));
			for(Path filepath:ds) {
				log.info("read "+filepath);
				readOneFile(filepath);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		
		
	}
	
	public static void readOneFile(Path filepath) {
		//String filename = "C:/timeseriesdatabase_source/sa/SAWS/ACS/ALIWAL-NORTH PLAATKOP.csv";
		String filename = filepath.toString();
		System.out.println("read file...");
		Table table = Table.readCSV(filename, ',');
		System.out.println("process...");
		
		ColumnReaderString cr_title = table.createColumnReader("title");	
		ColumnReaderSlashTimestamp cr_timestamp = table.createColumnReaderSlashTimestamp("Date");		
		ColumnReaderFloat cr_WV = table.createColumnReaderFloat("WndSpd"); //?
		//VSpd ignore
		ColumnReaderFloat cr_WD = table.createColumnReaderFloat("WndDir"); //?
		//StdDev ignore
		//Gust ignore
		ColumnReaderFloat cr_Ta_200 = table.createColumnReaderFloat("Temp"); //?	
		ColumnReaderFloat cr_rH_200 = table.createColumnReaderFloat("Hum"); //?
		//Pres ignore
		//BatVlt ignore
		//Rain ignore
		//GlobRad ignore
		//DifRad ignore
		//lat ignore
		//lon ignore
		
		ArrayList<TsEntry> list = new ArrayList<TsEntry>(table.rows.length);
		
		String[] sensorNames = new String[]{
				"Ta_200",
				"rH_200",
				"WD",
				"WV"
		};
		
		
		
		if(table.rows.length==0) {
			log.warn("empty");
			return;
		}
		
		String stationID = cr_title.get(table.rows[0]);
		
		
		for(String[] row:table.rows) {			
			list.add(TsEntry.of(cr_timestamp.get(row),
					cr_Ta_200.get(row, false),
					cr_rH_200.get(row, false),
					cr_WD.get(row, false),
					cr_WV.get(row, false)
					)); 
		}
		
		
		TimestampSeries tss = new TimestampSeries(stationID,sensorNames,list);
		
		System.out.println("write...");
		try {
			String outFile = TsDBFactory.OUTPUT_PATH+"/"+"south_africa_saws_acs"+"/"+tss.name+".dat";
			Util.createDirectoriesOfFile(outFile);
			TimestampSeries.writeToBinaryFile(tss, outFile);
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		
		
		
		//TsDBFactory.OUTPUT_PATH
		
	}

}
