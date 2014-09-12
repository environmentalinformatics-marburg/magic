package tsdb.remote;

import java.io.Serializable;

import tsdb.Station;
import tsdb.VirtualPlot;
import tsdb.util.Util;

public class PlotInfo implements Serializable {
	
	private static final long serialVersionUID = -304301220496293360L;

	public final String name;

	public final GeneralStationInfo generalStationInfo;
	public final boolean isStation;
	public final boolean isVIP;
	
	public PlotInfo(VirtualPlot virtualPlot) {
		this.name = virtualPlot.plotID;
		this.generalStationInfo = new GeneralStationInfo(virtualPlot.generalStation);
		this.isStation = false;
		this.isVIP = virtualPlot.isFocalPlot;
	}
	
	public PlotInfo(Station station) {
		Util.throwFalse(station.isPlot);
		this.name = station.stationID;
		this.generalStationInfo = new GeneralStationInfo(station.generalStation);
		this.isStation = true;
		this.isVIP = station.isVIP();
	}
	
	public PlotInfo(String name, String generalName, String regionName) {
		Util.throwNull(name);
		this.name = name;
		this.generalStationInfo = new GeneralStationInfo(generalName, regionName);
		this.isStation = false;
		this.isVIP = false;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		PlotInfo other = (PlotInfo) obj;
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name))
			return false;
		return true;
	}
	
	@Override
	public String toString() {
		return name;
	}
}
