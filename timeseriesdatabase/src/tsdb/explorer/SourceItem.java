package tsdb.explorer;

import tsdb.catalog.SourceEntry;

public class SourceItem {
	
	public final SourceEntry sourceEntry;
	public String generalStationName;
	public String regionName;
	public String plotid;
	
	public SourceItem(SourceEntry sourceEntry) {
		this.sourceEntry = sourceEntry;
		this.generalStationName = null;
		this.regionName = null;
		this.plotid = null;
	}

}
