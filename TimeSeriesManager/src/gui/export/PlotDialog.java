package gui.export;

import java.util.Arrays;
import java.util.Set;
import java.util.TreeSet;

import org.eclipse.core.databinding.observable.list.WritableList;
import org.eclipse.jface.databinding.viewers.ObservableListContentProvider;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.dialogs.TitleAreaDialog;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.List;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.ILabelProvider;
import org.eclipse.jface.viewers.ILabelProviderListener;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.ListViewer;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerFilter;
import org.eclipse.jface.viewers.ViewerSorter;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.widgets.Combo;

import tsdb.remote.PlotInfo;

import org.eclipse.jface.viewers.ComboViewer;

public class PlotDialog extends TitleAreaDialog {

	private CollectorModel model;

	private WritableList chosenPlots = new WritableList();
	private PlotInfo[] allPlotinfos;
	
	private String generalName = null;

	private ListViewer listViewerAvailableSensors;

	private final ViewerFilter plotFilter = new ViewerFilter() {
		@Override
		public boolean select(Viewer viewer, Object parentElement, Object element) {
			PlotInfo plotInfo = (PlotInfo)element;
			if(chosenPlots.contains(plotInfo)) {
				return false;
			}
			if(generalName==null) {
				return true;
			}			
			return plotInfo.generalStationInfo.longName.equals(generalName);
		}

	};

	/**
	 * Create the dialog.
	 * @param parentShell
	 * @param model 
	 */
	public PlotDialog(Shell parentShell, CollectorModel model) {
		super(parentShell);
		this.model = model;
		this.allPlotinfos = model.getAllPlotInfos();

		PlotInfo[] plotInfos = model.getQueryPlotInfos();
		if(plotInfos!=null) {
			chosenPlots.addAll(Arrays.asList(plotInfos));
		}	
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		setTitle("Plots");
		Composite area = (Composite) super.createDialogArea(parent);
		Composite container = new Composite(area, SWT.NONE);
		container.setLayout(new GridLayout(3, false));
		container.setLayoutData(new GridData(GridData.FILL_BOTH));

		Group grpChosenSensors = new Group(container, SWT.NONE);
		grpChosenSensors.setLayout(new FillLayout(SWT.HORIZONTAL));
		grpChosenSensors.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, true, 1, 1));
		grpChosenSensors.setText("Chosen Plots");

		ListViewer listViewerChosenSensors = new ListViewer(grpChosenSensors, SWT.BORDER | SWT.V_SCROLL | SWT.MULTI);
		List list_1 = listViewerChosenSensors.getList();
		list_1.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseDoubleClick(MouseEvent e) {
				StructuredSelection selection = (StructuredSelection) listViewerChosenSensors.getSelection();
				chosenPlots.removeAll(selection.toList());
				listViewerAvailableSensors.refresh();				
			}
		});
		listViewerChosenSensors.setContentProvider(new ObservableListContentProvider());
		listViewerChosenSensors.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				return ((PlotInfo)element).name;
			}
		});
		listViewerChosenSensors.setInput(chosenPlots);

		Composite grpAction = new Composite(container, SWT.NONE);
		GridData gd_grpAction = new GridData(SWT.LEFT, SWT.CENTER, false, true, 1, 1);
		gd_grpAction.heightHint = 336;
		grpAction.setLayoutData(gd_grpAction);
		grpAction.setLayout(new GridLayout(1, false));

		Group grpChooseSelected = new Group(grpAction, SWT.NONE);
		RowLayout rl_grpChooseSelected = new RowLayout(SWT.HORIZONTAL);
		rl_grpChooseSelected.justify = true;
		grpChooseSelected.setLayout(rl_grpChooseSelected);
		grpChooseSelected.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, false, false, 1, 1));
		grpChooseSelected.setText("choose selected");

		Button button_1 = new Button(grpChooseSelected, SWT.NONE);
		button_1.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				StructuredSelection selection = (StructuredSelection) listViewerAvailableSensors.getSelection();
				chosenPlots.addAll(selection.toList());
				listViewerAvailableSensors.refresh();
			}
		});
		button_1.setText("<");
		new Label(grpAction, SWT.NONE);

		Group grpRemoveSelected = new Group(grpAction, SWT.NONE);
		RowLayout rl_grpRemoveSelected = new RowLayout(SWT.HORIZONTAL);
		rl_grpRemoveSelected.justify = true;
		grpRemoveSelected.setLayout(rl_grpRemoveSelected);
		grpRemoveSelected.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, false, false, 1, 1));
		grpRemoveSelected.setText("remove selected");

		Button button_2 = new Button(grpRemoveSelected, SWT.NONE);
		button_2.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				StructuredSelection selection = (StructuredSelection) listViewerChosenSensors.getSelection();
				chosenPlots.removeAll(selection.toList());
				listViewerAvailableSensors.refresh();
			}
		});
		button_2.setText(">");
		new Label(grpAction, SWT.NONE);
		new Label(grpAction, SWT.NONE);
		new Label(grpAction, SWT.NONE);

		Group grpChooseAll = new Group(grpAction, SWT.NONE);
		grpChooseAll.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, false, false, 1, 1));
		grpChooseAll.setText("choose all");
		RowLayout rl_grpChooseAll = new RowLayout(SWT.HORIZONTAL);
		rl_grpChooseAll.justify = true;
		grpChooseAll.setLayout(rl_grpChooseAll);

		Button button = new Button(grpChooseAll, SWT.NONE);
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				for(PlotInfo plotInfo:allPlotinfos) {
					if(plotFilter.select(null, null, plotInfo)) {
						chosenPlots.add(plotInfo);
					}
				}
				listViewerAvailableSensors.refresh();
			}
		});
		button.setText("<<");
		new Label(grpAction, SWT.NONE);

		Group grpRemoveAll = new Group(grpAction, SWT.NONE);
		RowLayout rl_grpRemoveAll = new RowLayout(SWT.HORIZONTAL);
		rl_grpRemoveAll.justify = true;
		grpRemoveAll.setLayout(rl_grpRemoveAll);
		grpRemoveAll.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, false, false, 1, 1));
		grpRemoveAll.setText("remove all");

		Button button_3 = new Button(grpRemoveAll, SWT.NONE);
		button_3.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				chosenPlots.clear();
				listViewerAvailableSensors.refresh();
			}
		});
		button_3.setText(">>");

		Group grpAvailableSensors = new Group(container, SWT.NONE);
		grpAvailableSensors.setLayout(new GridLayout(1, false));
		grpAvailableSensors.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, true, 1, 1));
		grpAvailableSensors.setText("Available Plots");
		
		ComboViewer comboViewerGeneralNames = new ComboViewer(grpAvailableSensors, SWT.READ_ONLY);
		comboViewerGeneralNames.setContentProvider(ArrayContentProvider.getInstance());
		Combo comboGeneralNames = comboViewerGeneralNames.getCombo();
		comboGeneralNames.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				String name = (String) ((StructuredSelection) comboViewerGeneralNames.getSelection()).getFirstElement();
				if(name.equals("[all]")) {
					generalName = null;
				} else {
					generalName = name;
				}
				listViewerAvailableSensors.refresh();
			}
		});
		comboGeneralNames.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));		

		listViewerAvailableSensors = new ListViewer(grpAvailableSensors, SWT.BORDER | SWT.V_SCROLL | SWT.MULTI);
		List list = listViewerAvailableSensors.getList();
		list.setLayoutData(new GridData(SWT.FILL, SWT.FILL, false, true, 1, 1));
		list.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseDoubleClick(MouseEvent e) {
				StructuredSelection selection = (StructuredSelection) listViewerAvailableSensors.getSelection();
				chosenPlots.addAll(selection.toList());
				listViewerAvailableSensors.refresh();				
			}
		});
		listViewerAvailableSensors.setContentProvider(ArrayContentProvider.getInstance());
		listViewerAvailableSensors.setInput(allPlotinfos);
		listViewerAvailableSensors.setFilters(new ViewerFilter[]{plotFilter});
		listViewerAvailableSensors.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				return ((PlotInfo)element).name;
			}
		});
		
		
		Set<String> generalNameSet = new TreeSet<String>();
		for(PlotInfo plotinfo:allPlotinfos) {
			generalNameSet.add(plotinfo.generalStationInfo.longName);
		}

		String[] generalNames = new String[generalNameSet.size()+1];
		int i=0;
		generalNames[i] = "[all]";
		i++;
		for(String name:generalNameSet) {
			generalNames[i] = name;
			i++;
		}
		comboViewerGeneralNames.setInput(generalNames);
		comboViewerGeneralNames.setSelection(new StructuredSelection(generalNames[0]));

		return area;
	}

	/**
	 * Create contents of the button bar.
	 * @param parent
	 */
	@Override
	protected void createButtonsForButtonBar(Composite parent) {
		Button button = createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL,
				true);
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				model.setQueryPlotInfos((PlotInfo[]) chosenPlots.toArray(new PlotInfo[0]));
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
		return new Point(450, 659);
	}


}
