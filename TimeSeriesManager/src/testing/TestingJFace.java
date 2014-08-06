package testing;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.jface.action.MenuManager;
import org.eclipse.jface.action.StatusLineManager;
import org.eclipse.jface.action.ToolBarManager;
import org.eclipse.jface.window.ApplicationWindow;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.swt.widgets.Table;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;

public class TestingJFace extends ApplicationWindow {
	
	private static class DataElement {
		public final long value1;
		public final long value2;
		public DataElement(long value1, long value2) {
			this.value1 = value1;
			this.value2 = value2;
		}
	}
	
	
	private final FormToolkit formToolkit = new FormToolkit(Display.getDefault());
	private Table table;

	/**
	 * Create the application window.
	 */
	public TestingJFace() {
		super(null);
		createActions();
		addToolBar(SWT.FLAT | SWT.WRAP);
		addMenuBar();
		addStatusLine();
	}

	/**
	 * Create contents of the application window.
	 * @param parent
	 */
	@Override
	protected Control createContents(Composite parent) {
		Composite container = new Composite(parent, SWT.NONE);
		
		// define the TableViewer
		TableViewer viewer = new TableViewer(container, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.BORDER);
		
		// create the columns 
		// not yet implemented
		createColumns(viewer);
		
		
		
		
		table = viewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setBounds(74, 10, 300, 171);
		formToolkit.paintBordersFor(table);
		
		// set the content provider
		viewer.setContentProvider(ArrayContentProvider.getInstance());
		
		List<DataElement> inputList = new ArrayList<DataElement>();
		inputList.add(new DataElement(1,30));
		inputList.add(new DataElement(2,20));
		inputList.add(new DataElement(3,10));
		
		viewer.setInput(inputList);

		return container;
	}
	
	public void createColumns(TableViewer viewer) {
		
		TableViewerColumn colValue1 = new TableViewerColumn(viewer, SWT.NONE);
		colValue1.getColumn().setWidth(200);
		colValue1.getColumn().setText("Value 1");
		colValue1.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  DataElement e = (DataElement) element;
		    return ""+e.value1;
		  }
		});
		
		TableViewerColumn colValue2 = new TableViewerColumn(viewer, SWT.NONE);
		colValue2.getColumn().setWidth(200);
		colValue2.getColumn().setText("Value 2");
		colValue2.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  DataElement e = (DataElement) element;
		    return ""+e.value2;
		  }
		});	
		
	}

	/**
	 * Create the actions.
	 */
	private void createActions() {
		// Create the actions
	}

	/**
	 * Create the menu manager.
	 * @return the menu manager
	 */
	@Override
	protected MenuManager createMenuManager() {
		MenuManager menuManager = new MenuManager("menu");
		return menuManager;
	}

	/**
	 * Create the toolbar manager.
	 * @return the toolbar manager
	 */
	@Override
	protected ToolBarManager createToolBarManager(int style) {
		ToolBarManager toolBarManager = new ToolBarManager(style);
		return toolBarManager;
	}

	/**
	 * Create the status line manager.
	 * @return the status line manager
	 */
	@Override
	protected StatusLineManager createStatusLineManager() {
		StatusLineManager statusLineManager = new StatusLineManager();
		return statusLineManager;
	}

	/**
	 * Launch the application.
	 * @param args
	 */
	public static void main(String args[]) {
		try {
			TestingJFace window = new TestingJFace();
			window.setBlockOnOpen(true);
			window.open();
			Display.getCurrent().dispose();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Configure the shell.
	 * @param newShell
	 */
	@Override
	protected void configureShell(Shell newShell) {
		super.configureShell(newShell);
		newShell.setText("Testing JFace");
	}

	/**
	 * Return the initial size of the window.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(450, 300);
	}
}
