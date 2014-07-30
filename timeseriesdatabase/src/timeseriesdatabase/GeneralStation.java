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
	
	public Map<String,String> sensorNameTranlationMap;
	
	public List<Station> stationList;
	
	public List<VirtualPlot> virtualPlotList;
	
	public GeneralStation(String name) {
		this.name = name;
		this.stationList = new ArrayList<Station>();
		this.sensorNameTranlationMap = new HashMap<String,String>();
		this.virtualPlotList = new ArrayList<VirtualPlot>();
	}

}
