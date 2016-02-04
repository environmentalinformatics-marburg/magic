package tsdb.gui.bridge;

import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Button;

public class CheckButtonBridge {

	public interface CallBack {
		void call(boolean checked);
	}

	private final Button button;

	public CheckButtonBridge(Button button) {
		this.button = button;
	}
	
	
	
	public void addCheckChangedCallback(CallBack cb) {
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				cb.call(button.getSelection());
			}
		});
	}
	
	public void setChecked(boolean checked) {
		button.setSelection(checked);
	}

}
