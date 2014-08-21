package gui.query;

import java.util.stream.Stream;

import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.IContentProvider;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Text;




import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.Region;
import timeseriesdatabase.TimeSeriesDatabase;
import swing2swt.layout.BorderLayout;




import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.jface.viewers.ComboViewer;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormAttachment;

import swing2swt.layout.FlowLayout;

import org.eclipse.jface.viewers.ISelectionChangedListener;
import org.eclipse.jface.viewers.SelectionChangedEvent;

public class SensorQueryDialog extends Dialog {

	private TimeSeriesDatabase timeSeriesDatabase;
	private Region[] regions;
	//private GeneralStation[] generalStations;
	
	private ComboViewer comboViewerGeneralStation;

	/**
	 * Create the dialog.
	 * @param parentShell
	 * @param timeSeriesDatabase 
	 */
	public SensorQueryDialog(Shell parentShell, TimeSeriesDatabase timeSeriesDatabase) {
		super(parentShell);
		setShellStyle(SWT.MAX | SWT.RESIZE);
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.regions = timeSeriesDatabase.getRegions().toArray(new Region[0]);
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		Composite container = (Composite) super.createDialogArea(parent);
		container.setLayout(new BorderLayout(0, 0));

		Group grpQuery = new Group(container, SWT.NONE);
		grpQuery.setText("query");
		grpQuery.setLayoutData(BorderLayout.NORTH);
		grpQuery.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));

		Group grpRegion = new Group(grpQuery, SWT.NONE);
		grpRegion.setText("Region");
		grpRegion.setLayout(new FillLayout(SWT.HORIZONTAL));

		ComboViewer comboRegionViewer = new ComboViewer(grpRegion, SWT.READ_ONLY);

		comboRegionViewer.setContentProvider(ArrayContentProvider.getInstance());
		comboRegionViewer.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				Region region = (Region) element;
				return region.longName;
			}});
		comboRegionViewer.setInput(regions);
		comboRegionViewer.getCombo().setText(regions[0].longName);
		comboRegionViewer.addSelectionChangedListener(event->{			
			Object element = ((IStructuredSelection)event.getSelection()).getFirstElement();
			if(element!=null) {
				updateFromRegionCombo((Region) element);
			}
		});

		Group grpGeneralStation = new Group(grpQuery, SWT.NONE);
		grpGeneralStation.setText("General Station");
		grpGeneralStation.setLayout(new FillLayout(SWT.HORIZONTAL));

		comboViewerGeneralStation = new ComboViewer(grpGeneralStation, SWT.NONE);
		comboViewerGeneralStation.setContentProvider(ArrayContentProvider.getInstance());
		comboViewerGeneralStation.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				GeneralStation gs = (GeneralStation) element;
				return gs.longName;
			}});
		comboViewerGeneralStation.addSelectionChangedListener(new ISelectionChangedListener() {
			public void selectionChanged(SelectionChangedEvent event) {
			}
		});
		Combo combo_1 = comboViewerGeneralStation.getCombo();

		Group grpSensor = new Group(grpQuery, SWT.NONE);
		grpSensor.setText("Sensor");
		grpSensor.setLayout(new FillLayout(SWT.HORIZONTAL));

		ComboViewer comboViewer_1 = new ComboViewer(grpSensor, SWT.NONE);
		Combo combo_2 = comboViewer_1.getCombo();

		Group grpQuery_1 = new Group(grpQuery, SWT.NONE);
		grpQuery_1.setText("Query");

		Button btnUpdate = new Button(grpQuery_1, SWT.NONE);
		btnUpdate.setBounds(0, 21, 75, 25);
		btnUpdate.setText("update");

		Group grpResult = new Group(container, SWT.NONE);
		grpResult.setText("result");
		grpResult.setLayoutData(BorderLayout.CENTER);

		//grpQuery.pack();
		container.pack();

		updateFromRegionCombo((Region) ((IStructuredSelection)comboRegionViewer.getSelection()).getFirstElement());
		return container;
	}

	/**
	 * Create contents of the button bar.
	 * @param parent
	 */
	@Override
	protected void createButtonsForButtonBar(Composite parent) {
	}

	/**
	 * Return the initial size of the dialog.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(497, 300);
	}
	
	private void updateFromRegionCombo(Region region) {
		System.out.println("region: "+region);
		GeneralStation[] generalStations = timeSeriesDatabase.getGeneralStations(region).toArray(GeneralStation[]::new);
		comboViewerGeneralStation.setInput(generalStations);
	}	
}
