package testing;

import java.awt.Frame;
import java.awt.Graphics;
import java.awt.RenderingHints;
import java.awt.geom.Rectangle2D;

import org.eclipse.swt.SWT;
import org.eclipse.swt.awt.SWT_AWT;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.plot.Plot;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.AbstractXYItemRenderer;
import org.jfree.chart.renderer.xy.SamplingXYLineRenderer;
import org.jfree.chart.renderer.xy.XYDotRenderer;
import org.jfree.data.xy.DefaultXYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jfree.ui.ApplicationFrame;

import swing2swt.layout.BorderLayout;

import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;

public class TestingJFreeChart {
	
	ChartPanel chartPanel2;
	Frame canvasFrame;
	JFreeChart chart2;
	java.awt.Graphics2D g2d;
	java.awt.Canvas canvas;

	protected Shell shell;

	/**
	 * Launch the application.
	 * @param args
	 */
	public static void main(String[] args) {
		try {
			TestingJFreeChart window = new TestingJFreeChart();
			window.open();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Open the window.
	 */
	public void open() {
		Display display = Display.getDefault();
		createContents();
		shell.open();
		shell.layout();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
	}

	/**
	 * Create contents of the window.
	 */
	protected void createContents() {
		shell = new Shell();
		shell.setSize(450, 300);
		shell.setText("SWT Application");

		shell.setLayout(new BorderLayout(0, 0));


		
		
		
		final Composite drawarea = new Composite(shell, SWT.EMBEDDED);
		drawarea.addPaintListener(new PaintListener() {
			public void paintControl(PaintEvent e) {
				final java.awt.Graphics2D g2d = (java.awt.Graphics2D) canvas.getGraphics();
				chart2.draw(g2d, new Rectangle2D.Double(0,0,100,100));
			}
		});
		drawarea.redraw();
		drawarea.setLayoutData(BorderLayout.CENTER);
		canvasFrame = SWT_AWT.new_Frame(drawarea);
		canvas = new java.awt.Canvas(){
			@Override
			public void paint(Graphics g) {
				chart2.draw((java.awt.Graphics2D)g, new Rectangle2D.Double(0,0,this.getWidth(),this.getHeight()));
			}};
		canvasFrame.add(canvas);
		final java.awt.Graphics2D g2d = (java.awt.Graphics2D) canvas.getGraphics();
		//g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING,   RenderingHints.VALUE_ANTIALIAS_ON);
		
		
		
		
		
		
		double [][] A = {{1,2,3,4,5,6,7,8,9},{1,3,5,7,9,2,4,6,8}};

		DefaultXYDataset dataset = new DefaultXYDataset();
		dataset.addSeries("xy", A);
		
		// series2 enthaelt Punkte, die verbunden werden
		XYSeries series1 = new XYSeries("Punkte1");
		series1.add(0, 0);
		series1.add(1, 1);
		series1.add(2, 1);
		series1.add(3, 2);

		XYSeries series2 = new XYSeries("Punkte2");
		series2.add(1, 2);
		series2.add(2, 3);
		series2.add(3, 4);

		// Hinzufuegen von series1 und series2 zu der Datenmenge dataset
		XYSeriesCollection dataset2 = new XYSeriesCollection();
		dataset2.addSeries(series1);
		dataset2.addSeries(series2);

		XYDotRenderer dot = new XYDotRenderer();
		dot.setDotHeight(5);
		dot.setDotWidth(5);
		
		SamplingXYLineRenderer line = new SamplingXYLineRenderer();
		
		
		NumberAxis xax = new NumberAxis("time");
		NumberAxis yax = new NumberAxis("value");
		
		XYPlot plot = new XYPlot(dataset2,xax,yax, line);
		
		
		chart2 = new JFreeChart(plot);
		
		
		
		
		
		//ApplicationFrame punkteframe = new ApplicationFrame("Punkte");
		
		//chartPanel2 = new ChartPanel(chart2);
		
		
		
		//canvasFrame.add(chartPanel2);
		//canvasFrame.pack();
		
		/*chartPanel2.set
		
		punkteframe.setContentPane(chartPanel2);
		

		punkteframe.pack();
		punkteframe.setVisible(true);*/
		



	}
}
