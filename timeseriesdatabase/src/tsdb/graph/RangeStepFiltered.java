package tsdb.graph;

import tsdb.DataQuality;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.raw.iterator.LowQualityToNanIterator;
import tsdb.raw.iterator.QualityFlagIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class RangeStepFiltered extends Node.Abstract{ // just range and step
	
	private final Node source;
	private final DataQuality dataQuality;

	protected RangeStepFiltered(TsDB tsdb, Node source, DataQuality dataQuality) {
		super(tsdb);
		Util.throwNull(source, dataQuality);
		this.source = source;
		this.dataQuality = dataQuality;
	}
	
	public static RangeStepFiltered create(TsDB tsdb, Node source, DataQuality dataQuality) {
		if(DataQuality.Na==dataQuality) {
			throw new RuntimeException();
		}
		return new RangeStepFiltered(tsdb, source, dataQuality);
	}

	@Override
	public TsIterator get(Long start, Long end) {
		TsIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		QualityFlagIterator qf = new QualityFlagIterator(tsdb,input_iterator);
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
