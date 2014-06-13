package timeseriesdatabase;

import java.nio.file.Paths;

public class UseCaseInitDatabaes {

	public static void main(String[] args) {
		System.out.println("begin...");

		TimeSeriesDatabase timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();
				
		//timeSeriesDatabase.loadDirectoryOfOneExploratory(Paths.get("K:/HEG_short"));
		timeSeriesDatabase.loadDirectoryOfAllExploratories(Paths.get("K:/incoming_ftp/adl-m"));
		
		
		timeSeriesDatabase.close();
		System.out.println("...end");
		System.exit(0);
	}

}
