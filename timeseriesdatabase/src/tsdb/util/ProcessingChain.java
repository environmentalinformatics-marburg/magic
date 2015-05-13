package tsdb.util;

import java.util.List;

@Deprecated
public interface ProcessingChain {
	public abstract List<ProcessingChainEntry> getProcessingChain();
}
