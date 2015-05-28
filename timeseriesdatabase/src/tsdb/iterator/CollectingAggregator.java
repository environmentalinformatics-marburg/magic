package tsdb.iterator;

import java.util.ArrayList;

import tsdb.util.ProcessingChainEntry;
import tsdb.util.ProcessingChainSupplier;

/**
 * Interface for collecting aggregators
 * @author woellauer
 *
 */
public interface CollectingAggregator extends ProcessingChainEntry, ProcessingChainSupplier {
	int getAttributeCount();
	long calcNextOutput();
	ArrayList<Float>[] getOutputs();
}
