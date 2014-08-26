package tsdb.util;

import java.util.List;

public interface ProcessingChain {
	public abstract List<ProcessingChainEntry> getProcessingChain();
}
