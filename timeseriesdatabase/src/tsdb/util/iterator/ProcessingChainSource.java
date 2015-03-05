package tsdb.util.iterator;

import tsdb.util.ProcessingChainEntry;

public class ProcessingChainSource implements ProcessingChain  {
	public final ProcessingChainEntry entry;
	public ProcessingChainSource(ProcessingChainEntry entry) {
		this.entry = entry;
	}
	@Override
	public String getText() {
		return "|-"+entry.getProcessingTitle();
	}
}
