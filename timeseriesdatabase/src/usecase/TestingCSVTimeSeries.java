package usecase;

import java.io.IOException;
import java.nio.file.Paths;

import timeseriesdatabase.raw.CSVTimeSeries;
import timeseriesdatabase.raw.TimestampSeries;

public class TestingCSVTimeSeries {

	public static void main(String[] args) throws IOException {
		CSVTimeSeries csvTimeSeries = new CSVTimeSeries(Paths.get("c:/timeseriesdatabase_data_source_structure_kili/0000sav0/ra01_nas05_0000/ki_0000sav0_000wxt_201301311200_201302011406_mez_ra01_nas05_0000.asc"));
		TimestampSeries result = csvTimeSeries.readEntries();
	}

}
