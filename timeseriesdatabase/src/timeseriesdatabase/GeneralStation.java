package timeseriesdatabase;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * This class contains metadata that is associated with a group of stations like HEG or HEW.
 * @author woellauer
 *
 */
public class GeneralStation {
	
	public String name;
	
	public final Region region;
	
	public final String longName;
	
	public Map<String,String> sensorNameTranlationMap;
	
	public List<Station> stationList;
	
	public List<VirtualPlot> virtualPlotList;
	
	public final String group;
	
	public GeneralStation(String name, Region region, String longName, String group) {
		this.name = name;
		this.region = region;
		this.longName = longName;
		this.stationList = new ArrayList<Station>();
		this.sensorNameTranlationMap = new HashMap<String,String>();
		this.virtualPlotList = new ArrayList<VirtualPlot>();
		this.group = group;
	}

}
