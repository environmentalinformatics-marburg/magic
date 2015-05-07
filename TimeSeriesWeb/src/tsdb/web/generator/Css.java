package tsdb.web.generator;

public class Css {
	public final Tag tag;
	public Css(Tag tag) {
		this.tag = tag;
		tag.setAttribute("type", "text/css");
	}
	public void addLine(String text) {
		tag.element.setTextContent(tag.element.getTextContent()+text+"\n");
	}
}

