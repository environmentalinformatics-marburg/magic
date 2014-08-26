package processinggraph;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.raw.iterator.LowQualityToNanIterator;
import timeseriesdatabase.raw.iterator.QualityFlagIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class RangeStepFiltered extends Node.Abstract{ // just range and step
	
	private final Node source;
	private final DataQuality dataQuality;

	protected RangeStepFiltered(TimeSeriesDatabase timeSeriesDatabase, Node source, DataQuality dataQuality) {
		super(timeSeriesDatabase);
		Util.throwNull(source, dataQuality);
		this.source = source;
		this.dataQuality = dataQuality;
	}
	
	public static RangeStepFiltered create(TimeSeriesDatabase timeSeriesDatabase, Node source, DataQuality dataQuality) {
		if(DataQuality.Na==dataQuality) {
			throw new RuntimeException();
		}
		return new RangeStepFiltered(timeSeriesDatabase, source, dataQuality);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		QualityFlagIterator qf = new QualityFlagIterator(timeSeriesDatabase,input_iterator);
		if(qf==null||!qf.hasNext()) {
			return null;
		}
		if(DataQuality.NO==dataQuality) {
			return qf;
		}
		DataQuality filterQuality = dataQuality==DataQuality.EMPIRICAL?DataQuality.STEP:dataQuality;
		LowQualityToNanIterator bqi = new LowQualityToNanIterator(qf, filterQuality);
		if(bqi==null||!bqi.hasNext()) {
			return null;
		}		
		return bqi;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}
	
	@Override
	public boolean isContinuous() {
		return source.isContinuous();
	}

	@Override
	public boolean isConstantTimestep() {
		return source.isConstantTimestep();
	}
}
