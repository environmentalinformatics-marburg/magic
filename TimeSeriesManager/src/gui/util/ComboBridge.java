package gui.util;

import java.util.function.Function;

import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.ComboViewer;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.StructuredSelection;

public class ComboBridge<E> {

	private final ComboViewer comboViewer;

	public ComboBridge(ComboViewer comboViewer) {
		this.comboViewer = comboViewer;
	}

	public void setLabelMapper(Function<E,String> mapper) {
		comboViewer.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				if(element==null) {
					return "[!null!]";
				} else {
					@SuppressWarnings("unchecked")
					String result = mapper.apply((E) element);
					if(result==null) {
						return "[*null*]";
					} else {
						return result;
					}
				}
			}
		});
	}
	
	public void setInput(E[] input) {
		comboViewer.setContentProvider(ArrayContentProvider.getInstance());
		comboViewer.setInput(input);
	}
	
	public void setSelection(E element) {
		comboViewer.setSelection(new StructuredSelection(element));
	}

}
