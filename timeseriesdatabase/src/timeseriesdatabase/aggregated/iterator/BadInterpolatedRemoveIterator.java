package timeseriesdatabase.aggregated.iterator;

import java.util.Arrays;
import java.util.List;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

/**
 * Processed all interpolated values and removes all values that are of low quality.
 * @author woellauer
 *
 */
public class BadInterpolatedRemoveIterator extends MoveIterator {
	
	private TimeSeriesIterator input_iterator;
	private TimeSeriesEntry prev;
	private Sensor[] sensors;
	
	public static TimeSeriesSchema createSchema(TimeSeriesSchema input_schema) {
		String[] schema = input_schema.schema;
		boolean constantTimeStep = input_schema.constantTimeStep;
		int timeStep = input_schema.timeStep;
		if(!input_schema.isContinuous) {
			throw new RuntimeException("BadInterpolatedRemoveIterator needs continuous elements");
		}
		boolean isContinuous = true;		
		boolean hasQualityFlags = input_schema.hasQualityFlags;
		if(!input_schema.hasInterpolatedFlags) {
			throw new RuntimeException("BadInterpolatedRemoveIterator needs InterpolatedFlags");
		}
		boolean hasInterpolatedFlags = true;
		if(input_schema.hasQualityCounters) {
			throw new RuntimeException("QualityCounters not implemted");
		}
		boolean hasQualityCounters = false;
		return new TimeSeriesSchema(schema, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
		
	}

	public BadInterpolatedRemoveIterator(TimeSeriesDatabase timeSeriesDatabase, TimeSeriesIterator input_iterator) {
		super(createSchema(input_iterator.getOutputTimeSeriesSchema()));
		this.input_iterator = input_iterator;
		this.prev = null;
		this.sensors = timeSeriesDatabase.getSensors(input_iterator.getOutputTimeSeriesSchema());
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}

	@Override
	protected TimeSeriesEntry getNext() {
		if(input_iterator.hasNext()) {
			TimeSeriesEntry current = input_iterator.next();
			
			boolean someInterpolated= false;
			for(int i=0;i<current.interpolated.length;i++) {
				if(current.interpolated[i]) {
					someInterpolated = true;
					break;
				}
			}
			if(someInterpolated&&prev!=null) {
				
				float[] data = Arrays.copyOf(current.data,current.data.length);
				boolean[] interpolated = Arrays.copyOf(current.interpolated,current.interpolated.length);
				boolean someChecksFailed = false;
				for(int i=0;i<outputTimeSeriesSchema.columns;i++) {
					if(interpolated[i]) {
						if(!check(i,prev.data[i],data[i])) {
							someChecksFailed = true;
							interpolated[i] = false;
							data[i] = Float.NaN;
						}
					}
				}				
				prev = current;
				if(someChecksFailed) {
					return new TimeSeriesEntry(current.timestamp, data, current.qualityFlag, null, interpolated);
				} else {
					return current;
				}
			} else {
				prev = current;
				return current;
			}			
		} else {
			return null;
		}
	}

	@Override
	public String getIteratorName() {
		return "BadInterpolatedRemoveIterator";
	}
	
	
	private boolean check(int columnIndex, float prev, float value) {
		if(!sensors[columnIndex].checkPhysicalRange(value)) {
			return false;
		}
		if(!sensors[columnIndex].checkStepRange(prev, value)) {
			return false;
		}
		if(!sensors[columnIndex].checkEmpiricalRange(value)) {
			return false;
		}		
		return true;
	}

}
