package tsdb.gui.export;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

public class Processing1Dialog extends Dialog {

	protected Object result;
	protected Shell shell;
	
	private CollectorController controller;
	private String filename;
	private Text txtPrint;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param style
	 */
	public Processing1Dialog(Shell parent, CollectorController controller, String filename) {
		super(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE);
		this.controller = controller;
		this.filename = filename;
		setText("Processing");
	}
	
	private void callAsync(Runnable runnable) {
		getParent().getDisplay().asyncExec(runnable);
	}
	
	
	

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Object open() {
		createContents();
		shell.open();
		shell.layout();
		
		controller.setPrintCallback(s->callAsync(()->txtPrint.append(s+"\n")));		
		Thread worker = new Thread(()->controller.createZipFile(filename));
		worker.start();
		
		
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		return result;
	}

	/**
	 * Create contents of the dialog.
	 */
	private void createContents() {
		shell = new Shell(getParent(), getStyle());
		shell.setSize(450, 300);
		shell.setText(getText());
		shell.setLayout(new GridLayout(1, false));
		
		txtPrint = new Text(shell, SWT.BORDER | SWT.READ_ONLY | SWT.H_SCROLL | SWT.V_SCROLL | SWT.CANCEL | SWT.MULTI);
		txtPrint.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));

	}

}
