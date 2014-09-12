package tsdb.util.iterator;

import java.util.Arrays;

import tsdb.util.ProcessingChainEntry;

public class NewProcessingChainMultiSources implements NewProcessingChain {	
	public final NewProcessingChain[] sources;
	public final ProcessingChainEntry entry;
	public NewProcessingChainMultiSources(NewProcessingChain[] sources, ProcessingChainEntry entry) {
		this.sources = sources;
		this.entry = entry;
	}





	public NewProcessingChainMultiSources(TsIterator[] sources, ProcessingChainEntry entry) {		
		this.sources = Arrays.stream(sources).map(it->it.getProcessingChain()).toArray(NewProcessingChain[]::new);
		this.entry = entry;
	}

	public NewProcessingChainMultiSources(TsIterator primarySource, TsIterator[] secondarySources, ProcessingChainEntry entry) {	
		this(merge(primarySource,secondarySources), entry);
	}
	
	private static TsIterator[] merge(TsIterator primarySource, TsIterator[] secondarySources) {
		TsIterator[] itSources = new TsIterator[secondarySources.length+1];
		itSources[0] = primarySource;
		for(int i=0;i<secondarySources.length;i++) {
			itSources[i+1] = secondarySources[i];
		}
		return itSources;
	}


	@Override
	public String getText() {
		String s="(";
		for(NewProcessingChain e:sources) {
			s+=e.getText()+"  ";
		}
		s+=") -> "+entry.getProcessingTitle();
		return s;
	}
}
