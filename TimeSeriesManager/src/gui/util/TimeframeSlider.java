package gui.util;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseTrackListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;


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

	private boolean hover;
	private boolean hoverMin;
	private boolean hoverMax;

	private List<SliderChangeObserver> sliderChangeObserverList = new ArrayList<SliderChangeObserver>();

	private Color colorEmptyBackground;
	private Color colorWidgetBackground;
	private Color colorWidgetBorder;
	private Color colorBlack;
	private Color colorEmptyBackgroundHover;
	private Color colorDark;

	public TimeframeSlider(Composite parent, int style) {
		super(parent, style | SWT.DOUBLE_BUFFERED);
		this.min = 1000000;
		this.max = 2000000;
		this.selectedMin = min;
		this.selectedMax = max;
		this.sliding = slidingType.NONE;

		this.addPaintListener(this::onPaint);

		this.addMouseTrackListener(new MouseTrackListener(){
			@Override
			public void mouseEnter(MouseEvent e) {
				hover = true;
				hoverMin = isOnMinSlider(e.x);
				hoverMax = isOnMaxSlider(e.x);
				redraw();
			}
			@Override
			public void mouseExit(MouseEvent e) {
				hover = false;
				hoverMin = false;
				hoverMax = false;
				redraw();				
			}
			@Override
			public void mouseHover(MouseEvent e) {
			}});

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



		Display display = getDisplay();
		colorEmptyBackground = display.getSystemColor(SWT.COLOR_WHITE);
		colorWidgetBackground = display.getSystemColor(SWT.COLOR_WIDGET_BACKGROUND);
		colorWidgetBorder = display.getSystemColor(SWT.COLOR_WIDGET_BORDER);
		colorBlack = display.getSystemColor(SWT.COLOR_BLACK);
		colorDark = new Color(display,100,100,100);
		colorEmptyBackgroundHover = new Color(display,250,250,250);

		hover = false;
		hoverMin = false;
		hoverMax = false;
	}

	private void onPaint(PaintEvent e) {
		GC gc = e.gc;
		gc.setAdvanced(true);
		gc.setAntialias(SWT.ON);
		Rectangle clipping = gc.getClipping();
		if(hover) {
			gc.setBackground(colorEmptyBackgroundHover);
		} else {
			gc.setBackground(colorEmptyBackground);
		}
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

		gc.setBackground(colorWidgetBackground);
		gc.fillRectangle(sMinX, lineY-2, sMaxX-sMinX, 5);

		gc.setForeground(colorBlack);
		gc.drawLine(lineStart, lineY, lineEnd, lineY);

		if(hoverMin) {
			gc.setBackground(colorWidgetBorder);	
		} else {
			gc.setBackground(colorWidgetBackground);
		}
		gc.setForeground(colorWidgetBorder);
		gc.fillRectangle(sMinX-sWidth, 0, sWidth, clipping.height-1);
		//gc.drawRectangle(sMinX-sWidth, 0, sWidth, clipping.height-1);
		gc.drawLine(sMinX-sWidth,0,sMinX-sWidth,clipping.height-1);
		gc.setForeground(colorBlack);
		gc.drawLine(sMinX-sWidth, 0, sMinX, lineY);
		gc.drawLine(sMinX-sWidth, clipping.height-1, sMinX, lineY);
		gc.drawLine(sMinX,0,sMinX,clipping.height-1);


		if(hoverMax) {
			gc.setBackground(colorWidgetBorder);	
		} else {
			gc.setBackground(colorWidgetBackground);
		}
		gc.setForeground(colorWidgetBorder);
		gc.fillRectangle(sMaxX, 0, sWidth, clipping.height-1);
		//gc.drawRectangle(sMaxX, 0, sWidth, clipping.height-1);
		gc.drawLine(sMaxX+sWidth,0,sMaxX+sWidth,clipping.height-1);
		gc.setForeground(colorBlack);
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
	}

	private void onMouseUp(MouseEvent e) {
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
		hoverMin = isOnMinSlider(e.x);
		hoverMax = isOnMaxSlider(e.x);
		long diffX = windowToRealDiff(e.x-startX);
		switch(sliding) {
		case MIN:
			hoverMin = true;
			hoverMax = false;
			slideMin = selectedMin+diffX;
			if(slideMin<min) {
				slideMin = min;
			}
			if(slideMin>slideMax) {
				slideMin = slideMax;
			}
			break;
		case MAX:
			hoverMin = false;
			hoverMax = true;
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

	private long windowToRealDiff(long diff) {
		long windowRange = (lineEnd-lineStart);
		long realRange = (max-min);
		return (diff*realRange)/windowRange;
	}

	public void addSliderChangeObserver(SliderChangeObserver sliderChangeObserver) {
		sliderChangeObserverList.add(sliderChangeObserver);
	}

	public void fireSliderChange() {
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
