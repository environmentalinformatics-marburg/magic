package gui;

public class PrintBox {
	
	private TimeSeriesManager gui;
	
	public PrintBox(TimeSeriesManager gui) {
		this.gui = gui;
	}
	
	public void println(String text) {
		gui.textBox.append(text+"\n");
	}

	public void clear() {
		gui.textBox.setText("");
	}

}
