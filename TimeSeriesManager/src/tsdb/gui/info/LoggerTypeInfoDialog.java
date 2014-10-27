package tsdb.gui.info;



import java.rmi.RemoteException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;

import tsdb.LoggerType;
import tsdb.gui.bridge.TableBridge;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;

public class LoggerTypeInfoDialog extends Dialog {
	
	private static final Logger log = LogManager.getLogger();

	private RemoteTsDB tsdb;
	
	private TableBridge<LoggerType> tableViewBridge;

	public LoggerTypeInfoDialog(Shell parent, RemoteTsDB tsdb) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE, tsdb);

	}

	public LoggerTypeInfoDialog(Shell parent, int style,RemoteTsDB timeSeriesDatabase) {
		super(parent, style);
		this.tsdb = timeSeriesDatabase;
		setText("Logger Type Info");
	}

	public String open() {
		// Create the dialog window
		Shell shell = new Shell(getParent(), getStyle());
		shell.setText(getText());
		createContents(shell);
		shell.pack();
		shell.open();
		shell.setMaximized(true);
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		// Return the entered value, or null
		return null;
	}

	private void createContents(final Shell shell) {
		shell.setSize(450, 300);
		shell.setText(getText());
		shell.setLayout(new GridLayout(1, false));
		
		TableViewer tableViewer = new TableViewer(shell, SWT.BORDER | SWT.FULL_SELECTION | SWT.FILL);
		Table table = tableViewer.getTable();
		table.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));		
		tableViewBridge = new TableBridge<LoggerType>(tableViewer);
		
		tableViewBridge.addColumnText("Name", 100, l->l.typeName);
		tableViewBridge.addColumnText("Sensor Names", 100, l->Util.arrayToString(l.sensorNames));
		
		tableViewBridge.createColumns();
		
		try {
			LoggerType[] loggerTypes = tsdb.getLoggerTypes();
			tableViewBridge.setInput(loggerTypes);
		} catch (RemoteException e) {
			log.error(e);
		}

	}
}



