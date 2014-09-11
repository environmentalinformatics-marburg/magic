package tsdb.util.iterator;

import tsdb.util.ProcessingChainEntry;

public class NewProcessingChainOneInput implements NewProcessingChain {	
	public final NewProcessingChain source;
	public final ProcessingChainEntry entry;
	public NewProcessingChainOneInput(NewProcessingChain source, ProcessingChainEntry entry) {
		this.source = source;
		this.entry = entry;
	}
	@Override
	public String getText() {
		return source.getText()+" -> "+entry.getProcessingTitle();
	}
}
