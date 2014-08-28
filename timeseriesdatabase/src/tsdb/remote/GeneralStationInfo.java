package tsdb.remote;

import java.io.Serializable;

import tsdb.GeneralStation;
import tsdb.Region;

public class GeneralStationInfo implements Serializable{
	
	private static final long serialVersionUID = -5021875538014695128L;
	
	public final String name;
	public final String longname;
	public final String group;
	public final Region region;
	
	public GeneralStationInfo(GeneralStation generalStation) {
		this.name = generalStation.name;
		this.longname = generalStation.longName;
		this.group = generalStation.group;
		this.region = generalStation.region;
	}

}
