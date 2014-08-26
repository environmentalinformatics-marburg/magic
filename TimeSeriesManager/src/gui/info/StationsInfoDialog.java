package gui.info;



import java.util.Map.Entry;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;

import tsdb.Sensor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.util.Util;

public class StationsInfoDialog extends Dialog {

	TsDB timeSeriesDatabase; 

	public StationsInfoDialog(Shell parent, TsDB timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE, timeSeriesDatabase);

	}

	public StationsInfoDialog(Shell parent, int style,TsDB timeSeriesDatabase) {
		super(parent, style);
		this.timeSeriesDatabase = timeSeriesDatabase;
		setText("Station Info");
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
		;
		shell.setLayout(new GridLayout());
		Table table = new Table (shell, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		table.setLinesVisible (true);
		table.setHeaderVisible (true);
		GridData data = new GridData(SWT.FILL, SWT.FILL, true, true);
		data.heightHint = 200;
		table.setLayoutData(data);
		String[] titles = {"ID", "Logger Type","Longitude","Latitude","General Station", "Alternative ID"};
		for (int i=0; i<titles.length; i++) {
			TableColumn column = new TableColumn (table, SWT.NONE);
			column.setText (titles [i]);
		}	

		for(Station station:timeSeriesDatabase.getStations()) {
			TableItem item = new TableItem (table, SWT.NONE);
			item.setText (0, station.stationID);
			item.setText (1, tsdb.util.Util.ifnull(station.loggerType, x->x.typeName,()->"---"));
			item.setText (2, ""+ Util.ifNaN(station.geoPoslongitude,"---"));
			item.setText (3, ""+ Util.ifNaN(station.geoPosLatitude,"---"));
			item.setText (4, Util.ifnull(station.generalStation, x->x.name, ()->"---"));
			item.setText (5, Util.ifnull(station.alternativeID,"---"));
		}


		for (int i=0; i<titles.length; i++) {
			table.getColumn (i).pack ();
		}	


	}	

}

