package usecase;

import java.io.IOException;
import java.nio.file.Paths;

import timeseriesdatabase.loader.SensorHeader;
import timeseriesdatabase.loader.UDBFTimestampSeries;
import timeseriesdatabase.loader.UniversalDataBinFile;

/**
 * testing
 * @author woellauer
 *
 */
public class UseCaseReadMetadata {
	
	public static void main(String[] args) throws IOException {
		UniversalDataBinFile udbf = new UniversalDataBinFile(Paths.get("C:/timeseriesdatabase_data_source/HEG/HG31/20110511_^b0_0023.dat"));
		//UniversalDataBinFile udbf = new UniversalDataBinFile(Paths.get("C:/timeseriesdatabase_data_source/HEG/HG31/20091026_^b1_0011.dat"));
		UDBFTimestampSeries uDBFTimeSeries = udbf.getUDBFTimeSeries();
		for(SensorHeader header:uDBFTimeSeries.sensorHeaders) {
			System.out.println(header);
		}
	}

}
