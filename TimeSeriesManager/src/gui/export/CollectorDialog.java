package gui.export;

import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;

import tsdb.remote.RemoteTsDB;
import tsdb.util.TsDBLogger;

import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.RowData;
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;

public class CollectorDialog extends Dialog implements TsDBLogger {
	
	private final RemoteTsDB tsdb;

	protected Object result;
	protected Shell shell;
	private Text txtDfsdfsfdf;
	private Group grpRegion;
	private Label lblNewLabel;
	private Button button;
	private Group grpGoup;
	private Group grpGroup;
	private Button button_1;
	private Text txtHegHegHeg;
	private Button btnGetZipfile;
	private Text txtInterpolated;
	private Button button_2;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param style
	 */
	public CollectorDialog(Shell parent, RemoteTsDB tsdb) {
		super(parent, SWT.SHELL_TRIM | SWT.BORDER);
		setText("Export");
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
		shell.setSize(450, 282);
		shell.setText(getText());
		shell.setLayout(new GridLayout(3, false));
		
		grpRegion = new Group(shell, SWT.NONE);
		grpRegion.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 3, 1));
		grpRegion.setText("Region");
		grpRegion.setLayout(new GridLayout(3, false));
		
		lblNewLabel = new Label(grpRegion, SWT.NONE);
		lblNewLabel.setText("Exploratories");
		new Label(grpRegion, SWT.NONE);
		button = new Button(grpRegion, SWT.NONE);
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				onChooseRegion();				
			}
		});
		button.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, true, false, 1, 1));
		button.setText("...");
		
		Group grpSensors = new Group(shell, SWT.NONE);
		grpSensors.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, true, 1, 1));
		grpSensors.setText("Sensors");
		grpSensors.setLayout(new GridLayout(1, false));
		
		txtDfsdfsfdf = new Text(grpSensors, SWT.BORDER | SWT.READ_ONLY | SWT.V_SCROLL | SWT.MULTI);
		txtDfsdfsfdf.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));
		txtDfsdfsfdf.setText("Ta_200\r\nrH_200");
		
		Button btnChange = new Button(grpSensors, SWT.NONE);
		btnChange.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		btnChange.setText("...");
		
		grpGoup = new Group(shell, SWT.NONE);
		grpGoup.setLayout(new GridLayout(1, false));
		grpGoup.setLayoutData(new GridData(SWT.FILL, SWT.FILL, false, false, 1, 1));
		grpGoup.setText("Plots");
		
		txtHegHegHeg = new Text(grpGoup, SWT.BORDER | SWT.READ_ONLY | SWT.V_SCROLL | SWT.MULTI);
		txtHegHegHeg.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, true, 1, 3));
		txtHegHegHeg.setText("HEG01\r\nHEG02\r\nHEG03");
		
		button_1 = new Button(grpGoup, SWT.NONE);
		button_1.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		button_1.setText("...");
		
		grpGroup = new Group(shell, SWT.NONE);
		grpGroup.setLayout(new GridLayout(1, false));
		grpGroup.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, false, 1, 1));
		grpGroup.setText("Details");
		
		txtInterpolated = new Text(grpGroup, SWT.BORDER | SWT.READ_ONLY | SWT.V_SCROLL | SWT.MULTI);
		txtInterpolated.setText("Interpolated\r\nQuality: Empirical");
		txtInterpolated.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 3));
		
		button_2 = new Button(grpGroup, SWT.NONE);
		button_2.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		button_2.setText("...");
		new Label(shell, SWT.NONE);
		new Label(shell, SWT.NONE);
		
		btnGetZipfile = new Button(shell, SWT.NONE);
		btnGetZipfile.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1));
		btnGetZipfile.setText("Get Zip-File");
	}
	
	private void onChooseRegion() {
		Reg1 dialog = new Reg1(shell, new String[]{"a","b","c"},"a");
		if(IDialogConstants.OK_ID==dialog.open()) {
			System.out.println("OK");
		}		
	}
	
	
}
