package tsdb.util;

import tsdb.util.iterator.ProcessingChain;

public interface ProcessingChainSupplier {

	ProcessingChain getProcessingChain();
	
}
