package gui.sensorquery;

import gui.util.TimeSeriesView;
import gui.util.TimeframeSlider;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Slider;
import org.eclipse.wb.swt.SWTResourceManager;

import swing2swt.layout.BorderLayout;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.util.Pair;

import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.ProgressBar;
import org.eclipse.swt.layout.GridData;

public class MultiTimeSeriesExplorer extends Composite {

	private Canvas canvas;
	private Slider slider;

	private List<TimeSeriesView> timeSeriesViews;
	private List<Pair<Image,Long[]>> timeSeriesCache;

	private int timeSeriesHeight = 200;

	private long minTimestamp = Long.MAX_VALUE;
	private long maxTimestamp = Long.MIN_VALUE;

	private long viewMinTimestamp = Long.MAX_VALUE;
	private long viewMaxTimestamp = Long.MIN_VALUE;

	private TimeframeSlider timeframeSlider;

	/**
	 * Create the composite.
	 * @param parent
	 * @param style
	 */
	public MultiTimeSeriesExplorer(Composite parent, int style) {
		super(parent, style);
		setLayout(new GridLayout(2, false));

		timeframeSlider = new TimeframeSlider(this, SWT.NONE);
		GridData gd_canvasTimeFrameSlider = new GridData(SWT.FILL, SWT.CENTER, false, false, 1, 1);
		gd_canvasTimeFrameSlider.heightHint = 15;
		timeframeSlider.setLayoutData(gd_canvasTimeFrameSlider);
		timeframeSlider.addSliderChangeObserver(this::onTimeframSliderChange);
		timeframeSlider.setRealRange(minTimestamp, maxTimestamp,true);

		new Label(this, SWT.NONE);

		canvas = new Canvas(this, SWT.DOUBLE_BUFFERED);
		canvas.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));
		canvas.setBackground(SWTResourceManager.getColor(SWT.COLOR_WHITE));
		canvas.setLayout(new GridLayout(1, false));
		canvas.addPaintListener(e->onPaint(e.gc));

		slider = new Slider(this, SWT.VERTICAL);		
		slider.setLayoutData(new GridData(SWT.LEFT, SWT.FILL, false, false, 1, 1));
		slider.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				canvas.redraw();
			}
		});

		timeSeriesViews = new ArrayList<TimeSeriesView>();
		timeSeriesCache = new ArrayList<Pair<Image,Long[]>>();
	}

	@Override
	protected void checkSubclass() {
		// Disable the check that prevents subclassing of SWT components
	}

	public void addTimestampSeries(TimestampSeries timeSeries, AggregationInterval aggregationInterval, String title, TimestampSeries compare_timeSeries) {

		TimeSeriesView timeSeriesView = new TimeSeriesView();
		if(timeSeries.getFirstTimestamp()<minTimestamp) {
			if(viewMinTimestamp==minTimestamp) {
				viewMinTimestamp = timeSeries.getFirstTimestamp();
			}
			minTimestamp = timeSeries.getFirstTimestamp();
		}
		if(maxTimestamp<timeSeries.getLastTimestamp()) {
			if(viewMaxTimestamp==maxTimestamp) {
				viewMaxTimestamp = timeSeries.getLastTimestamp();
			}
			maxTimestamp = timeSeries.getLastTimestamp();			
		}
		timeframeSlider.setRealRange(minTimestamp, maxTimestamp,true);
		if(timeSeriesViews.isEmpty()) {
			timeframeSlider.setSelectedRange(minTimestamp, maxTimestamp);
		}
		timeSeriesView.setCanvas(canvas);
		timeSeriesView.updateViewData(timeSeries, aggregationInterval, title, compare_timeSeries);
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
		System.out.println("onPaint");
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
					if(vs[0]==viewMinTimestamp && vs[1]==viewMaxTimestamp && vs[2]==width && vs[3]==height) {
						cacheValid = true;
					}
				} 

				if(!cacheValid) {

					Image image = new Image(getDisplay(),width,height);
					GC imageGC = new GC(image);
					timeSeriesView.updateWindow(0, 0, width, height);
					timeSeriesView.setTimeRange(viewMinTimestamp, viewMaxTimestamp);
					timeSeriesView.paintCanvas(imageGC,false);
					gc.drawImage(image, xPos, yPos);

					if(cache!=null) {
						cache.a.dispose();
					}

					cache = new Pair<Image, Long[]>(image, new Long[]{viewMinTimestamp,viewMaxTimestamp,(long) width,(long) height});
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
		viewMinTimestamp = minTimestamp;
		viewMaxTimestamp = maxTimestamp;
		canvas.redraw();
	}

	public void onTimeframSliderChange(long selectedMin,long selectedMax) {
		System.out.println("onTimeframSliderChange "+selectedMin+"  "+selectedMax);
		viewMinTimestamp = selectedMin;
		viewMaxTimestamp = selectedMax;
		if(canvas!=null) {
			canvas.redraw();
		}
	}


}
