package tsdb.remote;

import java.io.Serializable;
import java.util.List;

import tsdb.StationProperties;
import tsdb.VirtualPlot;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;

public class VirtualPlotInfo implements Serializable {
	
	private static final long serialVersionUID = -288110404460514296L;
	public final String plotID;
	public final GeneralStationInfo generalStationInfo;
	public final int geoPosEasting;
	public final int geoPosNorthing;
	public final List<TimestampInterval<StationProperties>> intervalList;
	
	public VirtualPlotInfo(VirtualPlot virtualPlot) {		
		this.plotID = virtualPlot.plotID;
		this.generalStationInfo= Util.ifnull(virtualPlot.generalStation, gs->new GeneralStationInfo(gs));
		this.geoPosEasting = virtualPlot.geoPosEasting;
		this.geoPosNorthing = virtualPlot.geoPosNorthing;
		this.intervalList = virtualPlot.intervalList;
	}
}
