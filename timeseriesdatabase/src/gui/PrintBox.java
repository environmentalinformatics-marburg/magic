package gui;

public class PrintBox {
	
	private Gui gui;
	
	public PrintBox(Gui gui) {
		this.gui = gui;
	}
	
	public void println(String text) {
		gui.textBox.append(text+"\n");
	}

	public void clear() {
		gui.textBox.setText("");
	}

}
