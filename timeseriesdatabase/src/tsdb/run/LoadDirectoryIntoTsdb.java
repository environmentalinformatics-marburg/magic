package tsdb.run;

import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.TreeMap;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.loader.ki.TimeSeriesLoaderKiLi;
import tsdb.loader.ki.TimeSeriesLoaderKiLi_manual_tfi;

public class LoadDirectoryIntoTsdb {

	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();

		/*TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);


		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();		


		//Path path = Paths.get("c:/temp/ki_201411150000_missingFiles_asc");
		//Path path = Paths.get("C:/timeseriesdatabase_source/ki_tsm/20141205");
		//Path path = Paths.get("C:/timeseriesdatabase_source/ki_tsm/20141217");
		Path path = Paths.get("C:/timeseriesdatabase_source/ki_tsm/20150113");
		timeseriesloaderKiLi.loadOneDirectory_structure_kili(path , ascCollectorMap);

		timeseriesloaderKiLi.loadWithAscCollectorMapNewParser(ascCollectorMap);*/
		
		TimeSeriesLoaderKiLi_manual_tfi TimeSerieaLoaderKiLi_manual_tfi = new TimeSeriesLoaderKiLi_manual_tfi(tsdb);
		TimeSerieaLoaderKiLi_manual_tfi.loadOneDirectory_structure_kili_tfi(Paths.get(TsDBFactory.SOURCE_KI_TFI_PATH));



		tsdb.close();

	}

}
