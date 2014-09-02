package gui.info;



import java.rmi.RemoteException;

import org.apache.logging.log4j.Logger;
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
import tsdb.TsDB;
import tsdb.aggregated.AggregationType;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.util.Util;

public class SensorsInfoDialog extends Dialog {

	private static Logger log = Util.log;

	private RemoteTsDB timeSeriesDatabase; 

	public SensorsInfoDialog(Shell parent, RemoteTsDB timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE, timeSeriesDatabase);

	}

	public SensorsInfoDialog(Shell parent, int style,RemoteTsDB timeSeriesDatabase) {
		super(parent, style);
		this.timeSeriesDatabase = timeSeriesDatabase;
		setText("Sensor Info");
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
		try {
			shell.setLayout(new GridLayout());
			Table table = new Table (shell, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
			table.setLinesVisible (true);
			table.setHeaderVisible (true);
			GridData data = new GridData(SWT.FILL, SWT.FILL, true, true);
			data.heightHint = 400;
			table.setLayoutData(data);
			String[] titles = {"name", "physical min", "physical max", "step min", "step max", "empirical diff", "aggregation type", "interpolation"};
			for (int i=0; i<titles.length; i++) {
				TableColumn column = new TableColumn (table, SWT.NONE);
				column.setText (titles [i]);
			}	

			for(Sensor sensor:timeSeriesDatabase.getSensors()) {
				TableItem item = new TableItem (table, SWT.NONE);
				item.setText (0, sensor.name);
				item.setText (1, ""+(-Float.MAX_VALUE!=sensor.physicalMin?sensor.physicalMin:"---"));
				item.setText (2, ""+(Float.MAX_VALUE!=sensor.physicalMax?sensor.physicalMax:"---"));
				item.setText (3, ""+sensor.stepMin);
				item.setText (4, ""+(Float.MAX_VALUE!=sensor.stepMax?sensor.stepMax:"---"));
				item.setText (5, ""+Util.ifnull(sensor.empiricalDiff,"---"));

				String agg="";
				if(sensor.baseAggregationType == AggregationType.NONE) {
					agg="---";
				} else {
					agg += sensor.baseAggregationType;
				}

				item.setText (6, agg);
				item.setText (7, (sensor.useInterpolation?"interpolation":"---"));
			}


			for (int i=0; i<titles.length; i++) {
				table.getColumn (i).pack ();
			}

		} catch(RemoteException e) {
			log.error(e);
		}


	}	

}
