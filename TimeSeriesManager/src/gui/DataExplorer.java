package gui;

import org.eclipse.swt.widgets.Composite;

import swing2swt.layout.BorderLayout;

import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;

import swing2swt.layout.FlowLayout;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.raw.TimestampSeries;

import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.wb.swt.SWTResourceManager;

public class DataExplorer extends Composite {
	
	private Canvas canvas;
	
	private DataView dataView;

	/**
	 * Create the composite.
	 * @param parent
	 * @param style
	 */
	public DataExplorer(Composite parent, int style) {
		super(parent, style);
		setLayout(new BorderLayout(0, 0));
		
		canvas = new Canvas(this, SWT.NONE);
		canvas.setBackground(SWTResourceManager.getColor(SWT.COLOR_WHITE));
		canvas.addPaintListener(new PaintListener() {
			public void paintControl(PaintEvent e) {
				dataView.paintCanvas(e.gc);
			}
		});
		canvas.setEnabled(false);
		canvas.setLayoutData(BorderLayout.CENTER);
		
		/*Group grpControl = new Group(this, SWT.NONE);
		grpControl.setEnabled(false);
		grpControl.setLayoutData(BorderLayout.NORTH);
		grpControl.setText("Control");
		grpControl.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));
		
		Label lblNewLabel = new Label(grpControl, SWT.NONE);
		lblNewLabel.setText("New Label");*/
		
		/*Group grpStatus = new Group(this, SWT.NONE);
		grpStatus.setText("Status");
		grpStatus.setLayoutData(BorderLayout.SOUTH);
		grpStatus.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));
		
		Label lblNewLabel_1 = new Label(grpStatus, SWT.NONE);
		lblNewLabel_1.setText("New Label");*/
		
		dataView = new DataView();
		dataView.canvas = canvas; 

	}
	
	public TimestampSeries getData() {
		return dataView.resultTimeSeries;
	}

	@Override
	protected void checkSubclass() {
		// Disable the check that prevents subclassing of SWT components
	}
	
	public void setData(TimestampSeries resultTimeSeries, AggregationInterval aggregationInterval) {
		dataView.resultTimeSeries = resultTimeSeries;
		dataView.aggregationInterval = aggregationInterval;
		dataView.updateViewData();
		canvas.redraw();
		
	}
}
