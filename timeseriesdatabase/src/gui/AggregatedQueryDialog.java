package gui;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationType;
import timeseriesdatabase.aggregated.TimeSeries;

public class AggregatedQueryDialog extends Dialog {

	TimeSeriesDatabase timeSeriesDatabase;

	Canvas canvas;

	TimeSeries queryResult;

	public AggregatedQueryDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL, timeSeriesDatabase);

	}

	public AggregatedQueryDialog(Shell parent, int style,TimeSeriesDatabase timeSeriesDatabase) {
		super(parent, style);
		this.timeSeriesDatabase = timeSeriesDatabase;
		setText("Query");
	}

	public String open() {
		// Create the dialog window
		Shell shell = new Shell(getParent(), getStyle());
		shell.setText(getText());
		createContents(shell);
		//shell.pack();
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
		shell.setLayout(new GridLayout(2, false));
		
		new Label(shell, SWT.NONE).setText("general station");
		/*Text textGeneralStation = new Text(shell, SWT.BORDER);
		GridData gridDataGeneralStation = new GridData();
		gridDataGeneralStation.horizontalAlignment = SWT.FILL;
		gridDataGeneralStation.grabExcessHorizontalSpace = true;
		textGeneralStation.setLayoutData(gridDataGeneralStation);
		textGeneralStation.setText("HEG");*/
		
		
		Combo comboGeneralStation = new Combo(shell, SWT.BORDER);
		GridData gridDataGeneralStation = new GridData();
		gridDataGeneralStation.horizontalAlignment = SWT.FILL;
		gridDataGeneralStation.grabExcessHorizontalSpace = true;
		comboGeneralStation.setLayoutData(gridDataGeneralStation);
		comboGeneralStation.setItems(new String [] {"HEG", "HEW"});
		comboGeneralStation.setText("HEG");

		
		new Label(shell, SWT.NONE).setText("plot ID");		
		Combo comboPlotID = new Combo(shell, SWT.BORDER);
		GridData gridDataPlotID = new GridData();
		gridDataPlotID.horizontalAlignment = SWT.FILL;
		gridDataPlotID.grabExcessHorizontalSpace = true;
		comboPlotID.setLayoutData(gridDataPlotID);
		comboPlotID.setItems(new String [] {"HEG01", "...", "...", "..."});
		comboPlotID.setText("HEG01");
		
		
		new Label(shell, SWT.NONE).setText("sensor name");		
		Combo comboSensorName = new Combo(shell, SWT.BORDER);
		GridData gridDataSensorName = new GridData();
		gridDataSensorName.horizontalAlignment = SWT.FILL;
		gridDataSensorName.grabExcessHorizontalSpace = true;
		comboSensorName.setLayoutData(gridDataSensorName);
		comboSensorName.setItems(new String [] {"Ta_200", "...", "...", "..."});
		comboSensorName.setText("Ta_200");
		
		
		/*
		comboSensorName.setItems(new String [] {"Ta_200", "...", "...", "..."});
		comboSensorName.setText("Ta_200");
		comboSensorName.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));
		
		
		
		Text textSensorName = new Text(shell, SWT.BORDER);
		GridData gridDataSensorName = new GridData();
		gridDataSensorName.horizontalAlignment = SWT.FILL;
		gridDataSensorName.grabExcessHorizontalSpace = true;
		textSensorName.setLayoutData(gridDataSensorName);
		textSensorName.setText("Ta_200");*/
		
	}

	private void createContentsOLD(final Shell shell) {
		
		


		GridLayout gridLayout = new GridLayout();

		gridLayout.numColumns = 3;

		shell.setLayout(gridLayout);



		new Label(shell, SWT.NULL).setText("plot ID:");

		Text textPlotID = new Text(shell, SWT.SINGLE | SWT.BORDER);
		textPlotID.setText("HEG01");

		GridData gridData = new GridData(GridData.HORIZONTAL_ALIGN_FILL);

		gridData.horizontalSpan = 2;

		textPlotID.setLayoutData(gridData);



		new Label(shell, SWT.NULL).setText("sensor name:");
		Combo comboSensorName = new Combo(shell, SWT.NULL);
		comboSensorName.setItems(new String [] {"Ta_200", "...", "...", "..."});
		comboSensorName.setText("Ta_200");
		comboSensorName.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));



		Label label = new Label(shell, SWT.NULL);

		label.setText("...");

		label.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_CENTER));



		new Label(shell, SWT.NULL).setText("result:");

		canvas = new Canvas(shell, SWT.BORDER);

		gridData = new GridData(GridData.FILL_BOTH);

		gridData.widthHint = 80;

		gridData.heightHint = 80;

		gridData.verticalSpan = 3;

		canvas.setLayoutData(gridData);

		canvas.addPaintListener(new PaintListener() {

			public void paintControl(final PaintEvent event) {
				paintCanvas(event.gc);

			}

		});



		Button run = new Button(shell, SWT.PUSH);

		run.setText("query");

		gridData = new GridData(GridData.HORIZONTAL_ALIGN_FILL | GridData.VERTICAL_ALIGN_BEGINNING);

		gridData.horizontalIndent = 5;

		run.setLayoutData(gridData);

		run.addSelectionListener(new SelectionAdapter() {

			public void widgetSelected(SelectionEvent event) {
				run.setEnabled(false);	        	  
				runQuery();
				canvas.redraw();	        	  
				run.setEnabled(true);
			}

		});





	}


	private void runQuery() {
		queryResult = timeSeriesDatabase.queryBaseAggregatedDataGapFilled("HEG01", new String[]{"Ta_200"}, null, null);

	}

	private void paintCanvas(GC gc) {
		if(queryResult!=null) {
			float[] data = queryResult.data[0];
			float width = canvas.getSize().x;
			float height = canvas.getSize().y;
			float timeFactor = width/data.length;

			float minValue = Float.MAX_VALUE;
			float maxValue = -Float.MAX_VALUE;

			for(int offset=0;offset<data.length;offset++) {
				float value = data[offset];
				if(!Float.isNaN(value)) {
					if(value<minValue) {
						minValue = value;						
					}
					if(value>maxValue) {
						maxValue = value;						
					}
				}
			}

			float valueFactor = height/(maxValue-minValue);

			float valueOffset = -minValue;


			System.out.println("valueFactor: "+valueFactor);
			System.out.println("valueOffset: "+valueOffset);

			Float prevValue = null;

			for(int offset=0;offset<data.length;offset++) {
				float value = data[offset];
				if(!Float.isNaN(value)) {
					int x = (int) (offset*timeFactor);
					int y = (int)(((value+valueOffset)*valueFactor));
					if(prevValue!=null) {
						int xprev = (int) ((offset-1)*timeFactor);
						int yprev = (int)(((prevValue+valueOffset)*valueFactor));
						gc.drawLine(xprev, yprev, x, y);
					} else {
						gc.drawLine(x, y, x, y);
					}
					prevValue = value;
				} else {
					prevValue = null;
				}
			}
			System.out.println("data length: "+data.length);
		}

	}


}

