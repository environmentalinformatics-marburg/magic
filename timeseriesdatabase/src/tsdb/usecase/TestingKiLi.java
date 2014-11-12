package tsdb.usecase;

import java.nio.file.Paths;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.TsDB;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;
import tsdb.util.Util;

public class TestingKiLi {
	
	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) {
		System.out.println("begin...");
		
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		TimeSeriesLoaderKiLi timeseriesloader = new TimeSeriesLoaderKiLi(timeSeriesDatabase);
		timeSeriesDatabase.registerStreams();
		
		String kili_basepath = "c:/timeseriesdatabase_data_source_structure_kili/";
		
		timeseriesloader.loadDirectoryOfAllExploratories_structure_kili(Paths.get(kili_basepath));
		
		System.out.println("...end");
	}
	
	/*public static void mainOLD(String[] args) throws IOException, ParseException {
		String filename ="C:/timeseriesdatabase_data_source_structure_kili/0000cof4/ra01_nai05_0000/"+"ki_0000cof4_000rug_201307010925_201308090620_mez_ra01_nai05_0000.asc";
		KiLiCSV.readFile(Paths.get(filename));
	}*/

}
