package tsdb;

import java.util.stream.Stream;

public interface Plot {
	
	Stream<Plot> getNearestPlots();
	String getPlotID();
	
	public static Real of(Station station) {
		return new Real(station);
	}
	
	public static Virtual of(VirtualPlot virtualPlot) {
		return new Virtual(virtualPlot);
	}
	
	class Real implements Plot {		
		public final Station station;		
		public Real(Station station) {
			this.station = station;
		}		
		@Override
		public Stream<Plot> getNearestPlots() {
			return station.nearestStations.stream().map(s->new Real(s));			
		}
		@Override
		public String getPlotID() {
			return station.stationID;
		}
	}
		
	class Virtual implements Plot {		
		public final VirtualPlot virtualPlot;		
		public Virtual(VirtualPlot virtualPlot) {
			this.virtualPlot = virtualPlot;
		}		
		@Override
		public Stream<Plot> getNearestPlots() {
			return virtualPlot.nearestVirtualPlots.stream().map(s->new Virtual(s));			
		}
		@Override
		public String getPlotID() {
			return virtualPlot.plotID;
		}		
	}
}
