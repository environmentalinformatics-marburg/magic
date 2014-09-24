package tsdb.run;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.graph.Addition;
import tsdb.graph.Averaged;
import tsdb.graph.Continuous;
import tsdb.graph.ContinuousGen;
import tsdb.graph.QueryPlan;
import tsdb.util.TsDBLogger;

/**
 * Generates time series for general stations with average of contained station values
 * and stores it in cache database.
 * @author woellauer
 *
 */
public class CreateStationGroupAverageCache implements TsDBLogger{

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = TsDBFactory.createDefault();
		ContinuousGen continuousGen = QueryPlan.getContinuousGen(tsdb, DataQuality.STEP);

		for(String group:tsdb.getGeneralStationGroups()) {
			List<String> list = tsdb.getStationAndVirtualPlotNames(group).collect(Collectors.toList());
			System.out.println("create average: "+group+" -> "+list);
			long groupMinTimestamp = Long.MAX_VALUE;
			long groupMaxTimestamp = Long.MIN_VALUE;
			for(String plotID:list) {				
				long[] interval = tsdb.getBaseTimeInterval(plotID);				
				if(interval!=null) {
					if(interval[0]<groupMinTimestamp) {
						groupMinTimestamp = interval[0];
					}
					if(groupMaxTimestamp<interval[1]) {
						groupMaxTimestamp = interval[1];
					}
				}
			}

			if(groupMinTimestamp!=Long.MAX_VALUE && groupMaxTimestamp!=Long.MIN_VALUE) {
				System.out.println(group+" ********************************* "+TimeConverter.oleMinutesToLocalDateTime(groupMinTimestamp)+"\t - \t"+TimeConverter.oleMinutesToLocalDateTime(groupMaxTimestamp)+" **************************************************************** "+groupMinTimestamp+"\t-\t"+groupMaxTimestamp);
				List<Continuous> sources = new ArrayList<Continuous>();
				List<Continuous> additions = new ArrayList<Continuous>();
				for(String plotID:list) {
					try {
						Continuous continuous = continuousGen.get(plotID,null);
						Addition addition = Addition.createWithElevationTemperature(tsdb,continuous,plotID);
						if(addition!=null) {
							additions.add(addition);
						}
						sources.add(continuous);
					} catch (Exception e) {
						log.warn(e);
					}
				}
				
				Averaged averaged;
				
				if(additions.isEmpty()) {
					averaged = Averaged.create(tsdb, sources, 3);					
				} else {
					averaged = Averaged.create(tsdb, additions, 3);
				}
				
				tsdb.cacheStorage.writeNew(group, averaged.get(groupMinTimestamp, groupMaxTimestamp));
				//averaged.writeConsole(generalMinTimestamp, generalMaxTimestamp);
			}
		}
		tsdb.close();
		System.out.println("...end");
	}
}
