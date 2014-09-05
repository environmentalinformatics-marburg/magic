package gui.export;

import java.rmi.RemoteException;

import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.dialogs.TitleAreaDialog;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Text;

import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.TsDBLogger;

public class CollDialog extends TitleAreaDialog implements TsDBLogger {

	private CollectorController controller;
	private CollectorModel model;

	private final RemoteTsDB tsdb;

	protected Object result;
	protected Shell shell;
	private Text txtSensorNames;
	private Group grpRegion;
	private Label lblRegion;
	private Button button;
	private Group grpGoup;
	private Group grpGroup;
	private Button button_1;
	private Text txtQueryPlotInfos;
	private Text txtInterpolated;
	private Button button_2;

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public CollDialog(Shell parentShell, RemoteTsDB tsdb) {
		super(parentShell);
		this.tsdb = tsdb;
		this.controller = new CollectorController(tsdb);
		this.model = controller.getModel();
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		setMessage("Saves a set of time series in one zip-file");
		setTitle("Export Time Series");
		Composite area = (Composite) super.createDialogArea(parent);
		Composite container = new Composite(area, SWT.NONE);
		GridData gd_container = new GridData(GridData.FILL_BOTH);
		gd_container.heightHint = 189;
		container.setLayoutData(gd_container);


		container.setLayout(new GridLayout(3, false));

		grpRegion = new Group(container, SWT.NONE);
		grpRegion.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 3, 1));
		grpRegion.setText("Region");
		grpRegion.setLayout(new GridLayout(3, false));

		lblRegion = new Label(grpRegion, SWT.NONE);
		lblRegion.setText("?Region?");
		new Label(grpRegion, SWT.NONE);
		button = new Button(grpRegion, SWT.NONE);
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				new Reg1(shell, model).open();				
			}
		});
		button.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, true, false, 1, 1));
		button.setText("...");

		Group grpSensors = new Group(container, SWT.NONE);
		grpSensors.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, true, 1, 1));
		grpSensors.setText("Sensors");
		grpSensors.setLayout(new GridLayout(1, false));

		txtSensorNames = new Text(grpSensors, SWT.BORDER | SWT.READ_ONLY | SWT.V_SCROLL | SWT.MULTI);
		GridData gd_txtQueryPlotInfos = new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1);
		gd_txtQueryPlotInfos.minimumWidth = 150;
		txtSensorNames.setLayoutData(gd_txtQueryPlotInfos);
		txtSensorNames.setText("Ta_200\r\nrH_200");

		Button btnChange = new Button(grpSensors, SWT.NONE);
		btnChange.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				new SensorDialog(shell, model).open();	
			}
		});
		btnChange.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		btnChange.setText("...");

		grpGoup = new Group(container, SWT.NONE);
		grpGoup.setLayout(new GridLayout(1, false));
		grpGoup.setLayoutData(new GridData(SWT.FILL, SWT.FILL, false, true, 1, 1));
		grpGoup.setText("Plots");

		txtQueryPlotInfos = new Text(grpGoup, SWT.BORDER | SWT.READ_ONLY | SWT.V_SCROLL | SWT.MULTI);
		GridData gd_txtHegHegHeg = new GridData(SWT.LEFT, SWT.FILL, true, true, 1, 3);
		gd_txtHegHegHeg.minimumWidth = 100;
		txtQueryPlotInfos.setLayoutData(gd_txtHegHegHeg);
		txtQueryPlotInfos.setText("HEG01\r\nHEG02\r\nHEG03\r\nHEG04");

		button_1 = new Button(grpGoup, SWT.NONE);
		button_1.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				new PlotDialog(shell, model).open();
			}
		});
		button_1.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		button_1.setText("...");

		grpGroup = new Group(container, SWT.NONE);
		grpGroup.setLayout(new GridLayout(1, false));
		grpGroup.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, true, 1, 1));
		grpGroup.setText("Details");

		txtInterpolated = new Text(grpGroup, SWT.BORDER | SWT.READ_ONLY | SWT.V_SCROLL | SWT.MULTI);
		txtInterpolated.setText("Interpolated\r\nQuality: Empirical");
		txtInterpolated.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 3));

		button_2 = new Button(grpGroup, SWT.NONE);
		button_2.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		button_2.setText("...");



		bindModel();
		controller.initModel();

		return area;
	}

	/**
	 * Create contents of the button bar.
	 * @param parent
	 */
	@Override
	protected void createButtonsForButtonBar(Composite parent) {
		Button btnExport = createButton(parent, IDialogConstants.CLIENT_ID, "Export",
				true);
		btnExport.setText("Get Zip-File");
		btnExport.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				controller.createZipFile();
			}
		});

		createButton(parent, IDialogConstants.CANCEL_ID,
				IDialogConstants.CANCEL_LABEL, false);
	}

	/**
	 * Return the initial size of the dialog.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(446, 532);
	}

	private void bindModel() {
		model.addPropertyChangeCallback("regionLongName", lblRegion::setText);		
		model.addPropertyChangeCallback("querySensorNames", this::onChangeQuerySensorNames);
		model.addPropertyChangeCallback("queryPlotInfos", this::onChangeQueryPlotInfos);
	}
	
	private void onChangeQuerySensorNames(String[] SensorNames) {
		if(SensorNames!=null&&SensorNames.length>0) {
			txtSensorNames.setText("");
			for(String name:SensorNames) {
				txtSensorNames.append(name+"\n");
			}
		} else {
			txtSensorNames.setText("[empty]");
		}
	}
	
	private void onChangeQueryPlotInfos(PlotInfo[] queryPlotInfos) {
		System.out.println("onChangeQueryPlotInfos");
		if(queryPlotInfos!=null&&queryPlotInfos.length>0) {
			txtQueryPlotInfos.setText("");
			for(PlotInfo p:queryPlotInfos) {
				txtQueryPlotInfos.append(p.name+"\n");
			}
		} else {
			txtQueryPlotInfos.setText("[empty]");
		}
	}



}
