package tsdb.util.iterator;

import tsdb.util.ProcessingChainEntry;
import tsdb.util.ProcessingChainSupplier;

public interface ProcessingChain {	
	public String getText();
	
	public static ProcessingChainSource createUnknown() {		
		return ProcessingChainSource.createUnknown();
	}
	
	public static ProcessingChainSource of(ProcessingChainEntry entry) {
		return ProcessingChainSource.of(entry);
	}
	
	public static ProcessingChainOneSource of(ProcessingChain source, ProcessingChainEntry entry) {
		return ProcessingChainOneSource.of(source, entry);
	}
	
	public static ProcessingChainOneSource of(ProcessingChainSupplier source, ProcessingChainEntry entry) {
		return ProcessingChainOneSource.of(source, entry);
	}
	
	public static ProcessingChainOneSource of(ProcessingChain source, String entry) {
		return ProcessingChainOneSource.of(source, entry);
	}
	
	public static ProcessingChainOneSource of(ProcessingChainSupplier source, String entry) {
		return ProcessingChainOneSource.of(source, entry);
	}
}
