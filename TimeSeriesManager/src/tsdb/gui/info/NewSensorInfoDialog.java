package tsdb.gui.info;

import java.rmi.RemoteException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;

import tsdb.Sensor;
import tsdb.aggregated.AggregationType;
import tsdb.gui.bridge.TableBridge;
import tsdb.remote.RemoteTsDB;

public class NewSensorInfoDialog extends Dialog {
	
	private static final Logger log = LogManager.getLogger();

	private final RemoteTsDB tsdb;

	protected Object result;
	protected Shell shell;
	private Table table;
	private Button btnCheckButton;
	private TableBridge<Sensor> tableViewBridge;

	private TableViewer tableViewer;


	/**
	 * Create the dialog.
	 * @param parent
	 * @param style
	 */
	public NewSensorInfoDialog(Shell parent, RemoteTsDB tsdb) {
		super(parent, SWT.SHELL_TRIM | SWT.BORDER);
		this.setText("Sensor Info");
		this.tsdb = tsdb;
	}

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Object open() {
		createContents();
		shell.open();
		shell.layout();
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

		Composite composite = new Composite(shell, SWT.NONE);
		composite.setLayout(new RowLayout(SWT.HORIZONTAL));
		composite.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));

		btnCheckButton = new Button(composite, SWT.CHECK);
		btnCheckButton.setSelection(true);
		btnCheckButton.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				updateTableFilter();
			}
		});
		btnCheckButton.setText("just base sensors");

		tableViewer = new TableViewer(shell, SWT.BORDER | SWT.FULL_SELECTION | SWT.FILL);
		table = tableViewer.getTable();
		table.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));

		tableViewBridge = new TableBridge<Sensor>(tableViewer);

		tableViewBridge.addColumn("Name",100,Sensor::getName);
		tableViewBridge.addColumnFloat("Physical Min",100,Sensor::getPhysicalMin);
		tableViewBridge.addColumnFloat("Physical Min",100,Sensor::getPhysicalMax);
		tableViewBridge.addColumnFloat("Step Min",100,Sensor::getStepMin);
		tableViewBridge.addColumnFloat("Step Max",100,Sensor::getStepMax);
		tableViewBridge.addColumnFloat("Empirical Diff",100,Sensor::getEmpiricalDiff);
		tableViewBridge.addColumnText("Aggregation", 100, s->(s.baseAggregationType == AggregationType.NONE?"---":s.baseAggregationType.toString()));
		tableViewBridge.addColumnText("Interpolation", 100, s->(s.useInterpolation?"X":"---"));

		tableViewBridge.createColumns();
		//tableViewer.setContentProvider(ArrayContentProvider.getInstance());
		//tableViewer.setComparator(tableViewBridge);		
		
		updateTableContent();

	}

	private void updateTableContent() {
		Sensor[] sensors = null;
		try {
			sensors = tsdb.getSensors();
		} catch (RemoteException e) {
			log.error(e);
		}
		tableViewBridge.setInput(sensors);	
		updateTableFilter();
	}

	private void updateTableFilter() {
		if(btnCheckButton.getSelection()) {
			tableViewBridge.setFilter(s->s.baseAggregationType!=AggregationType.NONE);
		} else {
			tableViewBridge.setFilter(null);	
		}
	}
}
