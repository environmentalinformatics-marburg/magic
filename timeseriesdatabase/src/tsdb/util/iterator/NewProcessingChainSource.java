package tsdb.util.iterator;

import tsdb.util.ProcessingChainEntry;

public class NewProcessingChainSource implements NewProcessingChain  {
	public final ProcessingChainEntry entry;
	public NewProcessingChainSource(ProcessingChainEntry entry) {
		this.entry = entry;
	}
	@Override
	public String getText() {
		return "|-"+entry.getProcessingTitle();
	}
}
