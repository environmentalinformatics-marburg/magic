package tsdb.gui;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;

public class TestingImage {
	
	private static void drawText(Graphics2D gc, String text, float x, float y) {
		Rectangle2D rect = gc.getFontMetrics().getStringBounds(text,gc);
		System.out.println(rect);
		System.out.println(rect.getClass());
		x-=rect.getMinX();
		y-=rect.getMinY();
		gc.drawString(text, x, y);
	}
	
	public static void main(String[] args) throws IOException {
		
		BufferedImage bufferedImage = new BufferedImage(1500, 400, java.awt.image.BufferedImage.TYPE_INT_RGB);
		Graphics2D gc = bufferedImage.createGraphics();
		gc.setBackground(new Color(255, 255, 255));
		gc.clearRect(0, 0, bufferedImage.getWidth(), bufferedImage.getHeight());
		gc.setBackground(new Color(0, 0, 0));
		gc.clearRect(1, 1, bufferedImage.getWidth()-2, bufferedImage.getHeight()-2);
		gc.setBackground(new Color(255, 0, 0));
		gc.clearRect(2, 2, bufferedImage.getWidth()-4, bufferedImage.getHeight()-4);
		gc.setColor(new Color(0, 255, 0));
		drawText(gc,"draw",0,0);
		gc.dispose();
		ImageIO.write(bufferedImage, "png", new File("C:/timeseriesdatabase_output/"+"img.png"));
		
		/*TsDB tsDB = TsDBFactory.createDefault();
		ServerTsDB remoteTsDB = new ServerTsDB(tsDB);
		
		String queryType = null;
		String plotID = "HEG01";
		String[] columnNames = new String[]{"Ta_200"};
		AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		DataQuality dataQuality = DataQuality.STEP;
		boolean interpolated = false;
		TimestampSeries ts = remoteTsDB.plot(null, plotID, columnNames, aggregationInterval, dataQuality, interpolated);
		
		Display display = new Display();
		TimeSeriesView timeSeriesView = new TimeSeriesView(display);
		timeSeriesView.updateViewData(ts, aggregationInterval, "testing", null);
		Image image = new Image(display,2000,300);
		GC imageGC = new GC(image);
		timeSeriesView.updateWindow(0, 0, 2000,300);
		timeSeriesView.paintCanvas(imageGC,null);
		imageGC.dispose();
		
		
		ImageLoader loader = new ImageLoader();
		loader.data = new ImageData[] {image.getImageData()};
	    loader.save(TsDBFactory.get_CSV_output_path()+"swt.png", SWT.IMAGE_PNG);
		
		
		image.dispose();
		display.dispose();*/		
		
		
	}

}
