package gui.info;

import java.util.ArrayList;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.function.Predicate;

import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.jface.viewers.ViewerFilter;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Table;

public class TableViewBridge<E> extends ViewerComparator{

	/*
	 * 
	 * needed entries:
	 * 
	 * 1. comparator
	 * 2. printer
	 * 
	 * 
	 * 
	 * 
	 */

	private int compareIndex=0;
	private boolean sortAscending = true;
	private final TableViewer tableViewer;
	private ArrayList<ColumnMapper> columnMappers = new ArrayList<ColumnMapper>();
	private Function<Object,E> cast = (o)->(E)o;

	public class ColumnMapper {
		public final String title;
		public final Function<Object,String> textMapper;		
		public final BiFunction<Object,Object,Integer> compare;
		public final int textWidth;
		public ColumnMapper(String title, int textWidth, Function<Object,String> textMapper, BiFunction<Object,Object,Integer> compare) {
			this.title = title;
			this.textMapper = textMapper;
			this.compare = compare;
			this.textWidth = textWidth;
		}
		public <T extends Comparable<T>> ColumnMapper(String title, int textWidth, Function<Object, T> valueMapper) {
			this(title, textWidth, o->valueMapper.apply(o).toString(), (o1,o2)->valueMapper.apply(o1).compareTo(valueMapper.apply(o2)));
		}

		public <T extends Comparable<T>> ColumnMapper(String title, int textWidth, Function<Object,String> textMapper, Function<Object, T> compareValueMapper) {
			this(title, textWidth, textMapper, (o1,o2)->compareValueMapper.apply(o1).compareTo(compareValueMapper.apply(o2)));
		}
	}

	public void addColumn(ColumnMapper columnMapper) {
		columnMappers.add(columnMapper);
	}

	public <T extends Comparable<T>> void addColumn(String title, int textWidth, Function<E, T> valueMapper) {
		addColumn(new ColumnMapper(title, textWidth, cast.andThen(valueMapper)));
	}

	public <T extends Comparable<T>> void addColumn(String title, int textWidth, Function<E,String> textMapper, Function<E, T> compareValueMapper) {
		addColumn(new ColumnMapper(title, textWidth, cast.andThen(textMapper), cast.andThen(compareValueMapper)));
	}

	public <T extends Comparable<T>> void addColumnText(String title, int textWidth, Function<E,String> textMapper) {
		addColumn(new ColumnMapper(title, textWidth, cast.andThen(textMapper), cast.andThen(textMapper)));
	}

	public <T extends Comparable<T>> void addColumnInteger(String title, int textWidth, Function<E,Integer> integerMapper) {
		addColumn(new ColumnMapper(title,textWidth,cast.andThen(integerMapper)));
	}

	public void addColumnFloat(String title, int textWidth, Function<E,Float> floatMapper) {
		Function<Object,String> textMapper = o -> {
			Float v = floatMapper.apply((E)o);
			if(v==null||v==Float.MAX_VALUE||v==-Float.MAX_VALUE) {
				return "---";
			} else {
				return v.toString();
			}
		};
		BiFunction<Object,Object,Integer> compare = (o1,o2)->{
			Float f1 = floatMapper.apply((E)o1);
			Float f2 = floatMapper.apply((E)o2);
			if(f1==null||f2==null) {
				return 1;
			} else {
				return Float.compare((float)f1, (float)f2);
			}
		};
		addColumn(new ColumnMapper(title,textWidth,textMapper,compare));
	}




	public TableViewBridge(TableViewer tableViewer) {
		this.tableViewer = tableViewer;
		tableViewer.setContentProvider(ArrayContentProvider.getInstance());
		tableViewer.setComparator(this);
		
		Table table = tableViewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
	}

	@Override
	public int compare(Viewer viewer, Object o1, Object o2) {
		int cmp = columnMappers.get(compareIndex).compare.apply(o1, o2);
		return sortAscending?cmp:-cmp;
	}

	public ColumnLabelProvider getColumnLabelProvider(int columnIndex) {
		Function<Object, String> textMapper = columnMappers.get(columnIndex).textMapper;
		return new ColumnLabelProvider() {
			@Override
			public String getText(Object element) {
				return textMapper.apply(element);
			}
		};
	}

	public SelectionAdapter getSelectionSortListener(int thisSortColumn) {
		return new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				if(thisSortColumn==compareIndex) {
					sortAscending = !sortAscending;
				} else {
					sortAscending = true;
				}
				compareIndex = thisSortColumn;
				tableViewer.refresh();
			}			
		};
	}

	public void addTableViewerColumn(int columnIndex, String title, int width) {
		TableViewerColumn colStationName = new TableViewerColumn(tableViewer, SWT.NONE);
		colStationName.getColumn().setWidth(width);
		colStationName.getColumn().setText(title);
		colStationName.setLabelProvider(getColumnLabelProvider(columnIndex));
		colStationName.getColumn().addSelectionListener(getSelectionSortListener(columnIndex));	
	}

	public void createColumns() {		
		for(int i=0;i<columnMappers.size();i++) {
			addTableViewerColumn(i,columnMappers.get(i).title,columnMappers.get(i).textWidth);	
		}
	}

	public void setFilter(Predicate<E> filter) {
		if(filter!=null) {
			ViewerFilter viewerFilter = new ViewerFilter() {			
				@Override
				public boolean select(Viewer viewer, Object parentElement, Object o) {
					return filter.test((E)o);
				}
			};		
			tableViewer.setFilters(new ViewerFilter[]{viewerFilter});
		} else {
			tableViewer.setFilters(new ViewerFilter[0]);	
		}
	}
	
	public void setInput(E[] data) {
		tableViewer.setInput(data);
		Table table = tableViewer.getTable();
		for (int i=0; i<table.getColumnCount(); i++) {
			tableViewer.getTable().getColumn(i).pack ();
		}		
	}

}
