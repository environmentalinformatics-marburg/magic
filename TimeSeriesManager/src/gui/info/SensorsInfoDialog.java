package gui.info;



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
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationType;

public class SensorsInfoDialog extends Dialog {
	
	TimeSeriesDatabase timeSeriesDatabase; 

	public SensorsInfoDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE, timeSeriesDatabase);
		
	}
	
	public SensorsInfoDialog(Shell parent, int style,TimeSeriesDatabase timeSeriesDatabase) {
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
;
		shell.setLayout(new GridLayout());
		Table table = new Table (shell, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		table.setLinesVisible (true);
		table.setHeaderVisible (true);
		GridData data = new GridData(SWT.FILL, SWT.FILL, true, true);
		data.heightHint = 400;
		table.setLayoutData(data);
		String[] titles = {"name", "physical min", "physical max", "empirical min", "empirical max", "step min", "step max", "aggregation type", "interpolation"};
		for (int i=0; i<titles.length; i++) {
			TableColumn column = new TableColumn (table, SWT.NONE);
			column.setText (titles [i]);
		}	

		for(Sensor sensor:timeSeriesDatabase.getSensors()) {
			TableItem item = new TableItem (table, SWT.NONE);
			item.setText (0, sensor.name);
			item.setText (1, ""+sensor.physicalMin);
			item.setText (2, ""+sensor.physicalMax);
			item.setText (3, ""+sensor.empiricalMin);
			item.setText (4, ""+sensor.empiricalMax);
			item.setText (5, ""+sensor.stepMin);
			item.setText (6, ""+sensor.stepMax);
			
			String agg="";
			if(sensor.baseAggregationType == AggregationType.NONE) {
				agg="---";
			} else {
				agg += sensor.baseAggregationType;
			}
			
			item.setText (7, agg);
			item.setText (8, (sensor.useInterpolation?"interpolation":"---"));
		}
		
		
		for (int i=0; i<titles.length; i++) {
			table.getColumn (i).pack ();
		}	

	   
	  }	

}
