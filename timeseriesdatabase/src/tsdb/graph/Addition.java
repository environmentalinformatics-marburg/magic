package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNull;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.raw.TsEntry;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TsIterator;

public class Addition implements Continuous {
	
	private final Continuous source;
	private final float value;
	
	protected Addition(Continuous source, float value) {
		throwNull(source);
		this.source = source;
		this.value = value;
	}
	
	public static Addition create(Continuous source, float value) {
		return new Addition(source, value);
	}
	
	public static Addition createWithElevationTemperature(TsDB tsdb, Continuous source, String plotID) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot==null) {
			return null;
		}
		if(Float.isNaN(virtualPlot.elevationTemperature)) {
			return null;
		}
		return new Addition(source, -virtualPlot.elevationTemperature);
	}

	@Override
	public TsIterator get(Long start, Long end) {
		TsIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		
		return new InputProcessingIterator(input_iterator,input_iterator.getSchema()) {
			@Override
			protected TsEntry getNext() {
				if(!input_iterator.hasNext()) {
					return null;
				}
				TsEntry element = input_iterator.next();
				float[] data = element.data;
				float[] result = new float[data.length];
				for(int i=0;i<data.length;i++) {
					result[i] = data[i]+value;
				}
				return new TsEntry(element.timestamp, result);
			}			
		};
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isConstantTimestep() {
		return source.isConstantTimestep();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

	@Override
	public TsIterator getExactly(long start, long end) {
		return get(start,end);
	}

}
