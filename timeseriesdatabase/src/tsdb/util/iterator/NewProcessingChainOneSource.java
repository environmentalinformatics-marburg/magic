package tsdb.util.iterator;

import tsdb.util.ProcessingChainEntry;

public class NewProcessingChainOneSource implements NewProcessingChain {	
	public final NewProcessingChain source;
	public final ProcessingChainEntry entry;
	public NewProcessingChainOneSource(NewProcessingChain source, ProcessingChainEntry entry) {
		this.source = source;
		this.entry = entry;
	}
	public NewProcessingChainOneSource(TsIterator source, ProcessingChainEntry entry) {
		this.source = source.getProcessingChain();
		this.entry = entry;
	}
	@Override
	public String getText() {
		return source.getText()+" -> "+entry.getProcessingTitle();
	}
}
