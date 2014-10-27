package tsdb.gui.export;



import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.dialogs.TitleAreaDialog;
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
import tsdb.gui.bridge.CheckButtonBridge;
import tsdb.gui.bridge.ComboBridge;

public class DetailDialog extends TitleAreaDialog {
	
	private static final Logger log = LogManager.getLogger();

	private CollectorModel model;

	private boolean useInterpolation;
	private DataQuality dataQuality;
	private AggregationInterval aggregationInterval;
	private boolean writeDescription;
	private boolean writeAllInOne;

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
		this.writeDescription = model.getWriteDescription();
		this.writeAllInOne = model.getWriteAllInOne();
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
		CheckButtonBridge btnInterpolate = new CheckButtonBridge(new Button(container,SWT.CHECK));
		btnInterpolate.setChecked(useInterpolation);
		btnInterpolate.addCheckChangedCallback(c->useInterpolation=c);


		Label lblQualityChecked = new Label(container, SWT.NONE);
		lblQualityChecked.setText("quality check of measured values");
		Combo comboDataQuality = new Combo(container, SWT.READ_ONLY);
		comboDataQuality.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		ComboBridge<DataQuality> comboBridgeDQ = new ComboBridge<DataQuality>(comboDataQuality);
		comboBridgeDQ.setLabelMapper(dq->dq.getTextGUI());
		comboBridgeDQ.setInput(new DataQuality[]{DataQuality.NO,DataQuality.PHYSICAL,DataQuality.STEP,DataQuality.EMPIRICAL});
		comboBridgeDQ.setSelection(dataQuality);
		comboBridgeDQ.addSelectionChangedCallback(dq->dataQuality=dq);		

		txtTimeStep = new Text(container, SWT.READ_ONLY);
		txtTimeStep.setText("time step");
		txtTimeStep.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		Combo comboTimeStep = new Combo(container, SWT.READ_ONLY);
		comboTimeStep.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		ComboBridge<AggregationInterval> comboBridgeTimeStep = new ComboBridge<AggregationInterval>(comboTimeStep);
		comboBridgeTimeStep.setLabelMapper(a->a.getText());
		comboBridgeTimeStep.setInput(new AggregationInterval[]{AggregationInterval.HOUR,AggregationInterval.DAY,AggregationInterval.WEEK,AggregationInterval.MONTH, AggregationInterval.YEAR});
		comboBridgeTimeStep.setSelection(aggregationInterval);
		comboBridgeTimeStep.addSelectionChangedCallback(a->aggregationInterval=a);


		Label lblWriteSensorDescription = new Label(container, SWT.NONE);
		lblWriteSensorDescription.setText("write sensor description");
		CheckButtonBridge btnDescription = new CheckButtonBridge(new Button(container,SWT.CHECK));
		btnDescription.setChecked(writeDescription);
		btnDescription.addCheckChangedCallback(c->writeDescription=c);		

		Label lblWriteAllInOne = new Label(container, SWT.NONE);
		lblWriteAllInOne.setText("write all plots in one CSV-File");
		CheckButtonBridge btnAllInOne = new CheckButtonBridge(new Button(container,SWT.CHECK));
		btnAllInOne.setChecked(writeAllInOne);
		btnAllInOne.addCheckChangedCallback(c->writeAllInOne=c);
		
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
				model.setAggregationInterval(aggregationInterval);
				model.setWriteDescription(writeDescription);
				model.setWriteAllInOne(writeAllInOne);
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
