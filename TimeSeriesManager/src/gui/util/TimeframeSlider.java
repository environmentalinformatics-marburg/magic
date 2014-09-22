package gui.util;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;


public class TimeframeSlider extends Canvas {

	@FunctionalInterface
	public static interface SliderChangeObserver {
		void onChange(long selectedMin,long selectedMax);
	}

	private long min;
	private long max;

	private long selectedMin;
	private long selectedMax;

	private int lineStart;
	private int lineEnd;




	private static enum slidingType{NONE,MIN,MAX};
	private slidingType sliding;

	private final int sWidth = 10;
	private int sMinX;
	private int sMaxX;

	private int startX;
	private long slideMin;
	private long slideMax;

	private List<SliderChangeObserver> sliderChangeObserverList = new ArrayList<SliderChangeObserver>();

	public TimeframeSlider(Composite parent, int style) {
		super(parent, style | SWT.DOUBLE_BUFFERED);
		this.min = 1000000;
		this.max = 2000000;
		this.selectedMin = min;
		this.selectedMax = max;
		this.sliding = slidingType.NONE;

		this.addPaintListener(this::onPaint);
		//this.addMouseTrackListener(null);
		this.addMouseListener(new MouseListener() {
			@Override
			public void mouseDoubleClick(MouseEvent e) {
			}
			@Override
			public void mouseDown(MouseEvent e) {
				onMouseDown(e);
			}
			@Override
			public void mouseUp(MouseEvent e) {
				onMouseUp(e);
			}});
		this.addMouseMoveListener(this::onMouseMove);
	}

	private void onPaint(PaintEvent e) {
		GC gc = e.gc;
		gc.setAdvanced(true);
		gc.setAntialias(SWT.ON);
		Rectangle clipping = gc.getClipping();
		gc.setBackground(e.display.getSystemColor(SWT.COLOR_WHITE));
		gc.fillRectangle(0, 0, clipping.width-1, clipping.height-1);

		lineStart = sWidth;
		lineEnd = clipping.width-1-sWidth;




		int lineY = (clipping.height-1)/2;




		sMinX = realToWindow(selectedMin);
		if(sliding!=slidingType.NONE) {
			sMinX = realToWindow(slideMin);
		}

		sMaxX = realToWindow(selectedMax);
		if(sliding!=slidingType.NONE) {
			sMaxX = realToWindow(slideMax);
		}

		gc.setBackground(e.display.getSystemColor(SWT.COLOR_WIDGET_BACKGROUND));
		gc.fillRectangle(sMinX, lineY-2, sMaxX-sMinX, 5);

		gc.setForeground(e.display.getSystemColor(SWT.COLOR_BLACK));
		gc.drawLine(lineStart, lineY, lineEnd, lineY);

		gc.setBackground(e.display.getSystemColor(SWT.COLOR_WIDGET_BACKGROUND));
		gc.setForeground(e.display.getSystemColor(SWT.COLOR_WIDGET_BORDER));
		gc.fillRectangle(sMinX-sWidth, 0, sWidth, clipping.height-1);
		gc.drawRectangle(sMinX-sWidth, 0, sWidth, clipping.height-1);
		gc.setForeground(e.display.getSystemColor(SWT.COLOR_BLACK));
		gc.drawLine(sMinX-sWidth, 0, sMinX, lineY);
		gc.drawLine(sMinX-sWidth, clipping.height-1, sMinX, lineY);
		gc.drawLine(sMinX,0,sMinX,clipping.height-1);



		gc.setBackground(e.display.getSystemColor(SWT.COLOR_WIDGET_BACKGROUND));
		gc.setForeground(e.display.getSystemColor(SWT.COLOR_WIDGET_BORDER));
		gc.fillRectangle(sMaxX, 0, sWidth, clipping.height-1);
		gc.drawRectangle(sMaxX, 0, sWidth, clipping.height-1);
		gc.setForeground(e.display.getSystemColor(SWT.COLOR_BLACK));
		gc.drawLine(sMaxX, lineY, sMaxX+sWidth, 0);
		gc.drawLine(sMaxX, lineY, sMaxX+sWidth, clipping.height-1);	
		gc.drawLine(sMaxX,0,sMaxX,clipping.height-1);
	}

	private void onMouseDown(MouseEvent e) {
		int x = e.x;
		startX = x;
		slideMin = selectedMin;
		slideMax = selectedMax;

		if(isOnMinSlider(x)) {
			sliding = slidingType.MIN;
		} else if(isOnMaxSlider(x)) {
			sliding = slidingType.MAX;
		} else {
			sliding = slidingType.NONE;
		}
		System.out.println("onMouseDown: "+sliding);
	}

	private void onMouseUp(MouseEvent e) {
		System.out.println("onMouseUp");
		switch(sliding) {
		case MIN:
			if(selectedMin != slideMin) {
				selectedMin = slideMin;
				fireSliderChange();				
			}
			break;
		case MAX:
			if(selectedMax != slideMax) {
				selectedMax = slideMax;
				fireSliderChange();
			}
			break;
		default:
			break;
		}
		sliding = slidingType.NONE;
		redraw();
	}

	private void onMouseMove(MouseEvent e) {
		System.out.println("onMouseMove: "+sliding+"  "+e.button);

		long diffX = windowToRealDiff(e.x-startX);
		switch(sliding) {
		case MIN:
			slideMin = selectedMin+diffX;
			if(slideMin<min) {
				slideMin = min;
			}
			if(slideMin>slideMax) {
				slideMin = slideMax;
			}
			break;
		case MAX:
			slideMax = selectedMax+diffX;
			if(slideMax>max) {
				slideMax = max;
			}
			if(slideMax<slideMin) {
				slideMax = slideMin;
			}
			break;
		default:
			break;
		}

		redraw();
	}

	private boolean isOnMinSlider(int x) {
		return (sMinX-sWidth<=x)&&(x<=(sMinX));
	}

	private boolean isOnMaxSlider(int x) {
		return (sMaxX<=x)&&(x<=(sMaxX+sWidth));
	}

	private int realToWindow(long value) {
		long windowRange = (lineEnd-lineStart);
		long realRange = (max-min);
		return (int) (((value-min)*windowRange)/realRange)+lineStart;
	}

	/*private long windowToReal(int x) {
		long windowRange = (lineEnd-lineStart);
		long realRange = (max-min);
		return (((x-lineStart)*realRange)/windowRange)+min; 
	}*/

	private long windowToRealDiff(long diff) {
		long windowRange = (lineEnd-lineStart);
		long realRange = (max-min);
		return (diff*realRange)/windowRange;
	}

	public void addSliderChangeObserver(SliderChangeObserver sliderChangeObserver) {
		sliderChangeObserverList.add(sliderChangeObserver);
	}

	public void fireSliderChange() {
		System.out.println("fireSliderChange() "+min+"  "+max+"  "+selectedMin+"  "+selectedMax);
		for(SliderChangeObserver sliderChangeObserver:sliderChangeObserverList) {
			sliderChangeObserver.onChange(selectedMin, selectedMax);
		}
	}

	public void setRealRange(long min,long max, boolean sticky) {
		if(sticky) {
			if(selectedMin==this.min) {

				selectedMin = min;
				fireSliderChange();
			}
			if(this.selectedMax==this.max) {
				selectedMax = max;
				fireSliderChange();
			}
		}
		this.min = min;
		this.max = max;
		if(selectedMin<min||selectedMax>max) {
			if(selectedMin<min) {
				selectedMin = min;
			}
			if(selectedMax>max) {
				selectedMax = max;
			}
			fireSliderChange();
		}
		this.redraw();
	}

	public void setSelectedRange(long selectedMin,long selectedMax) {
		this.selectedMin = selectedMin;
		this.selectedMax = selectedMax;
		if(selectedMin<min) {
			selectedMin = min;
		}
		if(selectedMax>max) {
			selectedMax = max;
		}
		this.redraw();
	}


}
