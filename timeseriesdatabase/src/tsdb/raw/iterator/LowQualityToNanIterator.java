package tsdb.raw.iterator;

import tsdb.DataQuality;
import tsdb.raw.TsEntry;
import tsdb.util.TsDBLogger;
import tsdb.util.iterator.InputIterator;
import tsdb.util.iterator.TsIterator;

/**
 * Sets data values that are lower than chosen quality to NaN-values
 * @author woellauer
 *
 */
public class LowQualityToNanIterator extends InputIterator implements TsDBLogger {

	private DataQuality targetDataQuality;

	/**
	 * 
	 * @param input_iterator
	 * @param dataQuality lowest acceptable quality
	 */
	public LowQualityToNanIterator(TsIterator input_iterator, DataQuality dataQuality) {
		super(input_iterator, input_iterator.getSchema().copy());
		if(!input_iterator.getSchema().hasQualityFlags) {
			throw new RuntimeException("no quality flags in schema");
		}
		this.targetDataQuality = dataQuality;
	}

	@Override
	public boolean hasNext() {
		return input_iterator.hasNext();
	}

	@Override
	public TsEntry next() {
		TsEntry next = input_iterator.next();
		float[] data = next.data;
		DataQuality[] qualityFlag = next.qualityFlag;
		float[] resultData = new float[schema.length];
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
		return new TsEntry(next.timestamp,resultData,qualityFlag);
	}
}
