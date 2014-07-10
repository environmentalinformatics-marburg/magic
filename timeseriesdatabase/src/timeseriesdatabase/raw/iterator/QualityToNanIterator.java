package timeseriesdatabase.raw.iterator;

import java.util.List;

import org.apache.logging.log4j.Logger;

import timeseriesdatabase.DataQuality;
import timeseriesdatabase.raw.TimeSeriesEntry;
import util.ProcessingChainEntry;
import util.TimeSeriesSchema;
import util.Util;
import util.iterator.MoveIterator;
import util.iterator.TimeSeriesIterator;

/**
 * Sets data values that are lower than chosen quality to NaN-values
 * @author woellauer
 *
 */
public class QualityToNanIterator extends TimeSeriesIterator {

	private static final Logger log = Util.log;

	TimeSeriesIterator input_iterator;
	private DataQuality targetDataQuality;

	/**
	 * 
	 * @param input_iterator
	 * @param dataQuality lowest acceptable quality
	 */
	public QualityToNanIterator(TimeSeriesIterator input_iterator, DataQuality dataQuality) {
		super(TimeSeriesSchema.copy(input_iterator.getOutputTimeSeriesSchema()));
		if(!input_iterator.getOutputTimeSeriesSchema().hasQualityFlags) {
			throw new RuntimeException("no quality flags in schema");
		}
		this.input_iterator = input_iterator;
		this.targetDataQuality = dataQuality;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TimeSeriesEntry next() {
		TimeSeriesEntry next = input_iterator.next();
		float[] data = next.data;
		DataQuality[] qualityFlag = next.qualityFlag;
		float[] resultData = new float[outputTimeSeriesSchema.columns];
		for(int i=0;i<data.length;i++) {
			boolean isValid = true;
			DataQuality qf = qualityFlag[i];
			switch(targetDataQuality) {
			case NO:
				break;
			case PHYSICAL:
				if(qf==DataQuality.NO) {
					isValid = false;
				}
				break;
			case STEP:
				if(qf==DataQuality.NO || qf==DataQuality.PHYSICAL) {
					isValid = false;
				}
				break;
			case EMPIRICAL:
				if(qf==DataQuality.NO || qf==DataQuality.PHYSICAL || qf==DataQuality.STEP) {
					isValid = false;
				}
				break;
			default:
				log.warn("flag unknown: "+targetDataQuality);	
			}
			if(isValid) {
				resultData[i] = data[i]; 
			} else {
				resultData[i] = Float.NaN;
			}
		}
		return new TimeSeriesEntry(next.timestamp,resultData,qualityFlag);
	}

	@Override
	public String getIteratorName() {
		return "QualityToNanIterator";
	}
	
	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		List<ProcessingChainEntry> result = input_iterator.getProcessingChain();
		result.add(this);
		return result;
	}
}
