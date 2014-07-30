package usecase;

import java.io.IOException;
import java.nio.file.Paths;
import java.text.ParseException;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.raw.KiLiCSV;
import util.Util;

public class TestingKiLi {
	
	private static final Logger log = Util.log;

	public static void main(String[] args) {
		System.out.println("begin...");
		
		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
		timeSeriesDatabase.registerStreams();
		
		String basepath = "c:/timeseriesdatabase_data_source_structure_kili/";
		
		timeSeriesDatabase.loadDirectoryOfAllExploratories_structure_kili(Paths.get(basepath));
		
		System.out.println("...end");
	}
	
	/*public static void mainOLD(String[] args) throws IOException, ParseException {
		String filename ="C:/timeseriesdatabase_data_source_structure_kili/0000cof4/ra01_nai05_0000/"+"ki_0000cof4_000rug_201307010925_201308090620_mez_ra01_nai05_0000.asc";
		KiLiCSV.readFile(Paths.get(filename));
	}*/

}
