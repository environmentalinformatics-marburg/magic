package gui;



import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.catalog.SourceEntry;

public class SourceCatalogInfoDialog extends Dialog {

	TimeSeriesDatabase timeSeriesDatabase; 

	public SourceCatalogInfoDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE, timeSeriesDatabase);

	}

	public SourceCatalogInfoDialog(Shell parent, int style,TimeSeriesDatabase timeSeriesDatabase) {
		super(parent, style);
		this.timeSeriesDatabase = timeSeriesDatabase;
		setText("Source Catalog Info");
	}

	public String open() {
		// Create the dialog window
		Shell shell = new Shell(getParent(), getStyle());
		shell.setText(getText());
		createContents(shell);
		shell.pack();
		shell.open();
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
		shell.setLayout(new GridLayout());
		Table table = new Table (shell, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		table.setLinesVisible (true);
		table.setHeaderVisible (true);
		GridData data = new GridData(SWT.FILL, SWT.FILL, true, true);
		data.heightHint = 400;
		table.setLayoutData(data);

		String[] titles = {"Station Name", "First Timestamp", "Last Timestamp", "File Name"};
		for (int i=0; i<titles.length; i++) {
			TableColumn column = new TableColumn (table, SWT.NONE);
			column.setText (titles [i]);
		}
		for(SourceEntry entry:timeSeriesDatabase.sourceCatalog.getEntries()) {
			TableItem item = new TableItem (table, SWT.NONE);
			item.setText(0, entry.stationName);
			item.setText(1, TimeConverter.oleMinutesToText(entry.firstTimestamp));
			item.setText(2, TimeConverter.oleMinutesToText(entry.lastTimestamp));
			item.setText(3, entry.filename);
		}		

		for (int i=0; i<titles.length; i++) {
			table.getColumn (i).pack ();
		}

	}
}
