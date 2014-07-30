package timeseriesdatabase;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.Logger;

import util.TimestampInterval;
import util.Util;

/**
 * plot with data from a collection of data streams changing in time
 * @author woellauer
 *
 */
public class VirtualPlot {
	
	private static final Logger log = Util.log;

	public final String plotID;
	public final String generalStationName;

	public final List<TimestampInterval<Station>> intervalList;

	public VirtualPlot(String plotID, String generalStationName) {
		this.plotID = plotID;
		this.generalStationName = generalStationName;
		this.intervalList = new ArrayList<TimestampInterval<Station>>();
	}

	public void addStationEntry(Station station, Long start, Long end) {
		intervalList.add(new TimestampInterval<Station>(station, start, end));
	}

	/**
	 * Get list of stations with overlapping entries in time interval start - end
	 * @param queryStart
	 * @param queryEnd
	 * @param schema
	 * @return
	 */
	public List<Station> getStationList(Long queryStart, Long queryEnd, String[] schema) {

		/*

		null1             end1
		         start2          end2



		 */

		intervalList.sort( (a,b) -> {
			if(a.start==null) {
				if(b.start==null) {
					return 0;
				} else {
					return -1; // start1==null start2!=null
				}
			} else {
				if(b.start==null) {
					return 1; // start1!=null start2==null
				} else {
					return (a.start < b.start) ? -1 : ((a.start == b.start) ? 0 : 1);
				}
			}
		});

		List<Station> resultList = new ArrayList<Station>();
		Long currStart = queryStart;
		TimestampInterval<Station> currInterval = null;
		for(TimestampInterval<Station> interval:intervalList) {
			
			long intervalStart = util.Util.ifnull(interval.start,0l);
			long intervalEnd = util.Util.ifnull(interval.end,1000000000l);
			
			
			/*
			if(currInterval==null) { // process first interval in list
				if(queryStart==null) { // query start not defined
					currInterval = interval;
					currStart = interval.start;
				} else { // query start defined
					if(interval.start==null) { // query start defined  interval.start not defined       // check if query overlaps with interval
						
					}
				}
			}
			*/
			
			/*System.out.println("process interval: "+interval);
			
			if(currStart==null) {
				currInterval = interval;
				currStart = interval.start;
			} else if(interval.start==null){
				if(interval.end>queryStart) {
					System.out.println("return interval: "+interval);
				}
			}*/
			
			//if(currStart)
			System.out.println(intervalStart+"    "+TimeConverter.oleMinutesToText(intervalEnd));
		}
		return resultList;
	}
	
	/*private static boolean isInRange(Long aStart, Long aEnd, Long bStart, Long bEnd) {
		
	}*/

}
