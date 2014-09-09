package gui.export;

import gui.util.ComboBridge;

import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.dialogs.TitleAreaDialog;
import org.eclipse.jface.viewers.ComboViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import tsdb.DataQuality;
import tsdb.aggregated.AggregationInterval;
import tsdb.util.TsDBLogger;

public class DetailDialog extends TitleAreaDialog implements TsDBLogger {

	private CollectorModel model;
	private Button btnInterpolate;

	private boolean useInterpolation;
	private DataQuality dataQuality;
	private AggregationInterval aggregationInterval;
	
	private Text txtTimeStep;

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public DetailDialog(Shell parentShell, CollectorModel model) {
		super(parentShell);
		this.model = model;
		this.useInterpolation = model.getUseInterpolation();
		this.dataQuality = model.getDataQuality();
		this.aggregationInterval = model.getAggregationInterval();
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		setMessage("settings of exported time series");
		setTitle("Details");
		Composite area = (Composite) super.createDialogArea(parent);
		Composite container = new Composite(area, SWT.NONE);
		container.setLayout(new GridLayout(2, false));
		container.setLayoutData(new GridData(GridData.FILL_BOTH));
				
				Label lblNewLabel = new Label(container, SWT.SHADOW_NONE);
				lblNewLabel.setText("interpolate missing values if possible");
		
				btnInterpolate = new Button(container, SWT.CHECK);
				btnInterpolate.addSelectionListener(new SelectionAdapter() {
					@Override
					public void widgetSelected(SelectionEvent e) {
						useInterpolation = btnInterpolate.getSelection();
					}
				});
				btnInterpolate.setSelection(useInterpolation);

		Label lblQualityChecked = new Label(container, SWT.NONE);
		lblQualityChecked.setText("quality check of measured values");		

		Combo comboDataQuality = new Combo(container, SWT.READ_ONLY);
		comboDataQuality.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				switch(comboDataQuality.getSelectionIndex()) {
				case 0:
					dataQuality = DataQuality.NO;
					break;
				case 1:
					dataQuality = DataQuality.PHYSICAL;
					break;
				case 2:
					dataQuality = DataQuality.STEP;
					break;
				case 3:
					dataQuality = DataQuality.EMPIRICAL;
					break;
				default:
					log.warn("quality unknown");
					dataQuality = DataQuality.NO;
				}

			}
		});
		
		comboDataQuality.setItems(new String[] {"0: no", "1: physical", "2: physical + step", "3: physical + step + empirical"});
		comboDataQuality.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		
		switch(dataQuality) {
		case NO:
			comboDataQuality.select(0);
			break;
		case PHYSICAL:
			comboDataQuality.select(1);
			break;
		case STEP:
			comboDataQuality.select(2);
			break;
		case EMPIRICAL:
			comboDataQuality.select(3);
			break;		
		default:
			log.warn("data quality unknown");
			comboDataQuality.select(0);
		}		
		
		txtTimeStep = new Text(container, SWT.READ_ONLY);
		txtTimeStep.setText("time step");
		txtTimeStep.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		
		ComboViewer comboViewer = new ComboViewer(container, SWT.READ_ONLY);
		Combo combo = comboViewer.getCombo();
		combo.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		ComboBridge<AggregationInterval> comboBridge = new ComboBridge<AggregationInterval>(comboViewer);
		
		Label lblWriteSensorDescription = new Label(container, SWT.NONE);
		lblWriteSensorDescription.setText("write sensor description");
		
		Button btnCheckButton = new Button(container, SWT.CHECK);
		comboBridge.setLabelMapper(a->a.getText());
		comboBridge.setInput(new AggregationInterval[]{AggregationInterval.HOUR,AggregationInterval.DAY,AggregationInterval.WEEK,AggregationInterval.MONTH, AggregationInterval.YEAR});
		comboBridge.setSelection(aggregationInterval);		
		


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
				model.setUseInterpolation(useInterpolation);
				model.setDataQuality(dataQuality);
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
		return new Point(450, 300);
	}

}
