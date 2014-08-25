package gui.sensorquery;

import java.util.ArrayList;
import java.util.List;

import gui.query.TimeSeriesView;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.wb.swt.SWTResourceManager;

import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.Pair;

import org.eclipse.swt.widgets.Slider;

import swing2swt.layout.BorderLayout;

import org.eclipse.swt.widgets.Scale;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.MouseWheelListener;
import org.eclipse.swt.events.MouseEvent;

public class MultiTimeSeriesExplorer extends Composite {

	private Canvas canvas;
	private Slider slider;

	private List<TimeSeriesView> timeSeriesViews;
	private List<Pair<Image,Long[]>> timeSeriesCache;

	private int timeSeriesHeight = 200;

	private long minTimestamp = Long.MAX_VALUE;
	private long maxTimestamp = Long.MIN_VALUE;

	/**
	 * Create the composite.
	 * @param parent
	 * @param style
	 */
	public MultiTimeSeriesExplorer(Composite parent, int style) {
		super(parent, style);

		setLayout(new BorderLayout(0, 0));

		canvas = new Canvas(this, SWT.DOUBLE_BUFFERED);
		canvas.setBackground(SWTResourceManager.getColor(SWT.COLOR_WHITE));
		//canvas.setBackground(SWTResourceManager.getColor(SWT.COLOR_INFO_BACKGROUND));
		canvas.setLayout(new BorderLayout(0, 0));

		slider = new Slider(this, SWT.VERTICAL);
		slider.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				canvas.redraw();
			}
		});
		slider.setLayoutData(BorderLayout.EAST);
		canvas.addPaintListener(e->onPaint(e.gc));

		timeSeriesViews = new ArrayList<TimeSeriesView>();
		timeSeriesCache = new ArrayList<Pair<Image,Long[]>>();
	}

	@Override
	protected void checkSubclass() {
		// Disable the check that prevents subclassing of SWT components
	}

	public void addTimestampSeries(TimestampSeries timeSeries, AggregationInterval aggregationInterval, String title) {

		TimeSeriesView timeSeriesView = new TimeSeriesView();
		if(timeSeries.getFirstTimestamp()<minTimestamp) {
			minTimestamp = timeSeries.getFirstTimestamp();
		}
		if(maxTimestamp<timeSeries.getLastTimestamp()) {
			maxTimestamp = timeSeries.getLastTimestamp();
		}
		timeSeriesView.setCanvas(canvas);
		timeSeriesView.updateViewData(timeSeries, aggregationInterval, title);
		timeSeriesViews.add(timeSeriesView);
		timeSeriesCache.add(null);
		int selection = 0;
		int minimum = 0;
		int maximum = timeSeriesViews.size();
		int thumb = 0;
		int increment = 1;
		int pageIncrement = 3;
		slider.setValues(selection, minimum, maximum, thumb, increment, pageIncrement);
		slider.setMaximum(maximum); // needed!!
		canvas.redraw();
	}

	public void onPaint(GC gc) {
		Point size = canvas.getSize();
		int offset = slider.getSelection();
		System.out.println("offset "+offset+" maximum: "+slider.getMaximum());
		
		int seriesInWindow = size.y/timeSeriesHeight-1;
		if(timeSeriesViews.size()>=seriesInWindow) {
			slider.setMaximum(timeSeriesViews.size()-seriesInWindow);
		} else {
			slider.setMaximum(0);
		}
		
		
		


		for(int i=0;i<timeSeriesViews.size();i++) {

			TimeSeriesView timeSeriesView = timeSeriesViews.get(i);

			int xPos = 0;
			int yPos = i*timeSeriesHeight-(offset*timeSeriesHeight);
			int width = size.x;
			int height = timeSeriesHeight;

			if(yPos>-30&&yPos<size.y-30) {

				Pair<Image, Long[]> cache = timeSeriesCache.get(i);

				boolean cacheValid=false;
				if(cache!=null) {					
					Long[] vs = cache.b;
					if(vs[0]==minTimestamp && vs[1]==maxTimestamp && vs[2]==width && vs[3]==height) {
						cacheValid = true;
					}
				} 

				if(!cacheValid) {

					Image image = new Image(getDisplay(),width,height);
					GC imageGC = new GC(image);
					timeSeriesView.updateWindow(0, 0, width, height);
					timeSeriesView.setTimeRange(minTimestamp, maxTimestamp);
					timeSeriesView.paintCanvas(imageGC,false);
					gc.drawImage(image, xPos, yPos);

					if(cache!=null) {
						cache.a.dispose();
					}

					cache = new Pair<Image, Long[]>(image, new Long[]{minTimestamp,maxTimestamp,(long) width,(long) height});
					timeSeriesCache.add(i, cache);


					/*//System.out.println(xPos+", "+yPos+", "+width+", "+height);
					timeSeriesView.updateWindow(xPos, yPos, width, height);
					timeSeriesView.setTimeRange(minTimestamp, maxTimestamp);

					timeSeriesView.paintCanvas(gc,false);*/

				}
				
				gc.drawImage(cache.a, xPos, yPos);
				


			}
		}


	}

	public void clearTimestampSeries() {
		timeSeriesViews.clear();
		timeSeriesCache.clear();
		minTimestamp = Long.MAX_VALUE;
		maxTimestamp = Long.MIN_VALUE;
		canvas.redraw();
	}
}
