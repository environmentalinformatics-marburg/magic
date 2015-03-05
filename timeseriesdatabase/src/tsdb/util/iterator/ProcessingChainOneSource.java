package tsdb.util.iterator;

import tsdb.util.ProcessingChainEntry;

public class ProcessingChainOneSource implements ProcessingChain {	
	public final ProcessingChain source;
	public final ProcessingChainEntry entry;
	public ProcessingChainOneSource(ProcessingChain source, ProcessingChainEntry entry) {
		this.source = source;
		this.entry = entry;
	}
	public ProcessingChainOneSource(TsIterator source, ProcessingChainEntry entry) {
		this.source = source.getProcessingChain();
		this.entry = entry;
	}
	@Override
	public String getText() {
		return source.getText()+" -> "+entry.getProcessingTitle();
	}
}
