package tsdb.run;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.DataQuality;
import tsdb.TsDBFactory;
import tsdb.TimeConverter;
import tsdb.TsDB;
import tsdb.graph.Addition;
import tsdb.graph.Averaged;
import tsdb.graph.Continuous;
import tsdb.graph.ContinuousGen;
import tsdb.graph.QueryPlan;
import static tsdb.util.AssumptionCheck.*;
/**
 * Generates time series for general stations with average of contained station values
 * and stores it in cache database.
 * @author woellauer
 *
 */
public class CreateStationGroupAverageCache {

	private static final Logger log = LogManager.getLogger();

	public interface CbPrint {
		public void println(String text);
	}

	private final TsDB tsdb;
	private CbPrint cbPrint;

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = TsDBFactory.createDefault();

		new CreateStationGroupAverageCache(tsdb).run();

		tsdb.close();
		System.out.println("...end");
	}

	public CreateStationGroupAverageCache(TsDB tsdb) {
		this(tsdb,text->System.out.println(text));
	}

	public CreateStationGroupAverageCache(TsDB tsdb, CbPrint cbPrint) {
		throwNulls(tsdb,cbPrint);
		this.tsdb = tsdb;
		this.cbPrint = cbPrint;
	}

	public void run() {

		long startRunTime = System.currentTimeMillis();

		ContinuousGen continuousGen = QueryPlan.getContinuousGen(tsdb, DataQuality.STEP);

		for(String group:tsdb.getGeneralStationGroups()) {
			List<String> list = tsdb.getStationAndVirtualPlotNames(group).collect(Collectors.toList());
			cbPrint.println("create average: "+group+" -> "+list);
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
				cbPrint.println(group+" ********************************* "+TimeConverter.oleMinutesToLocalDateTime(groupMinTimestamp)+"\t - \t"+TimeConverter.oleMinutesToLocalDateTime(groupMaxTimestamp)+" **************************************************************** "+groupMinTimestamp+"\t-\t"+groupMaxTimestamp);
				List<Continuous> sources = new ArrayList<Continuous>();
				List<Continuous> additions = new ArrayList<Continuous>();
				for(String plotID:list) {
					try {
						Continuous continuous = continuousGen.get(plotID,null);
						if(continuous!=null) {
							Addition addition = Addition.createWithElevationTemperature(tsdb,continuous,plotID);
							if(addition!=null) {
								additions.add(addition);
							}
							sources.add(continuous);
						} else {
							//log.warn("no stream of "+plotID);
						}
					} catch (Exception e) {
						e.printStackTrace();
						log.warn(e);
					}
				}

				final int MIN_AVERAGE = 3;

				Averaged averaged = null;

				if(averaged==null && additions.size()>=MIN_AVERAGE) {
					averaged = Averaged.of(tsdb, additions, MIN_AVERAGE);
				}

				if(averaged==null && sources.size()>=MIN_AVERAGE) {
					averaged = Averaged.of(tsdb, sources, MIN_AVERAGE);
				}

				if(averaged!=null) {
					tsdb.cacheStorage.writeNew(group, averaged.get(groupMinTimestamp, groupMaxTimestamp));
					//averaged.writeConsole(generalMinTimestamp, generalMaxTimestamp);
				} else {
					log.warn("not enough sources for average: "+group);
				}
			}
		}

		long endRunTime = System.currentTimeMillis();
		cbPrint.println("CreateStationGroupAverageCache run time: "+(endRunTime-startRunTime)/1000+" s");

	}
}
