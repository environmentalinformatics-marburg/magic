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

public class LoadDirectoryIntoTsdb {

	public static void main(String[] args) {
		TsDB tsdb = TsDBFactory.createDefault();

		TimeSeriesLoaderKiLi timeseriesloaderKiLi = new TimeSeriesLoaderKiLi(tsdb);


		TreeMap<String,Path> ascCollectorMap = new TreeMap<String,Path>();		


		//Path path = Paths.get("c:/temp/ki_201411150000_missingFiles_asc");
		Path path = Paths.get("C:/timeseriesdatabase_source/ki_tsm/20141205");
		timeseriesloaderKiLi.loadOneDirectory_structure_kili(path , ascCollectorMap);

		timeseriesloaderKiLi.loadWithAscCollectorMapNewParser(ascCollectorMap);



		tsdb.close();

	}

}
