package gui.sensorquery;

import java.util.ArrayList;
import java.util.List;

import gui.query.TimeSeriesView;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.wb.swt.SWTResourceManager;

import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;

public class MultiTimeSeriesExplorer extends Composite {

	private Canvas canvas;
	private List<TimeSeriesView> timeSeriesViews;

	/**
	 * Create the composite.
	 * @param parent
	 * @param style
	 */
	public MultiTimeSeriesExplorer(Composite parent, int style) {
		super(parent, style);
		setLayout(new FillLayout(SWT.HORIZONTAL));
		
		canvas = new Canvas(this, SWT.NONE);
		canvas.setBackground(SWTResourceManager.getColor(SWT.COLOR_INFO_BACKGROUND));
		canvas.addPaintListener(e->onPaint(e.gc));
		
		timeSeriesViews = new ArrayList<TimeSeriesView>();
	}

	@Override
	protected void checkSubclass() {
		// Disable the check that prevents subclassing of SWT components
	}
	
	public void addTimestampSeries(TimestampSeries timeSeries, AggregationInterval aggregationInterval) {
		TimeSeriesView timeSeriesView = new TimeSeriesView();
		timeSeriesView.setCanvas(canvas);
		timeSeriesView.updateViewData(timeSeries, aggregationInterval);
		timeSeriesViews.add(timeSeriesView);
		canvas.redraw();
	}
	
	public void onPaint(GC gc) {
		Point size = canvas.getSize();
		for(int i=0;i<timeSeriesViews.size();i++) {
			TimeSeriesView timeSeriesView = timeSeriesViews.get(i);
			
			int xPos = 0;
			int yPos = i*100;
			int width = size.x;
			int height = 100;
			System.out.println(xPos+", "+yPos+", "+width+", "+height);
			timeSeriesView.updateWindow(xPos, yPos, width, height);
			
			timeSeriesView.paintCanvas(gc,false);
		}		
	}
	
	public void clearTimestampSeries() {
		timeSeriesViews.clear();
		canvas.redraw();
	}
}
