package gui;

import java.time.LocalDateTime;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.DateTime;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;

import swing2swt.layout.BorderLayout;
import swing2swt.layout.FlowLayout;
import util.Pair;

import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.RowData;

public class BeginEndDateTimeDialog extends Dialog {

	protected Shell shlQueryTimeInterval;
	
	private Pair<LocalDateTime, LocalDateTime> result;
	
	DateTime dateBegin;
	DateTime timeBegin;
	DateTime dateEnd;
	DateTime timeEnd;
	private Button btnBeginOfData;
	private Button btnEndDateOf;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param style
	 */
	public BeginEndDateTimeDialog(Shell parent) {
		super(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE);
		result = null;
		setText("SWT Dialog");
	}

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Pair<LocalDateTime, LocalDateTime> open() {
		createContents();
		shlQueryTimeInterval.open();
		shlQueryTimeInterval.layout();
		Display display = getParent().getDisplay();
		while (!shlQueryTimeInterval.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		return result;
	}

	/**
	 * Create contents of the dialog.
	 */
	private void createContents() {
		shlQueryTimeInterval = new Shell(getParent(), SWT.DIALOG_TRIM);
		shlQueryTimeInterval.setSize(390, 516);
		shlQueryTimeInterval.setText("Query Time Interval");
		RowLayout rl_shlQueryTimeInterval = new RowLayout(SWT.VERTICAL);
		rl_shlQueryTimeInterval.wrap = false;
		shlQueryTimeInterval.setLayout(rl_shlQueryTimeInterval);
		
		Group grpBegin = new Group(shlQueryTimeInterval, SWT.NONE);
		grpBegin.setLayoutData(new RowData(371, 205));
		grpBegin.setText("Begin");
		grpBegin.setLayout(new BorderLayout(0, 0));
		
		dateBegin = new DateTime(grpBegin, SWT.CALENDAR /*| SWT.DROP_DOWN*/);
		dateBegin.setLayoutData(BorderLayout.CENTER);
		dateBegin.setEnabled(false);
		
		btnBeginOfData = new Button(grpBegin, SWT.CHECK);
		btnBeginOfData.setSelection(true);
		btnBeginOfData.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				if(btnBeginOfData.getSelection()) {
					dateBegin.setEnabled(false);
					timeBegin.setEnabled(false);
				} else {
					dateBegin.setEnabled(true);
					timeBegin.setEnabled(true);
				}
			}
		});
		btnBeginOfData.setLayoutData(BorderLayout.NORTH);
		btnBeginOfData.setText("begin date of data");
		timeBegin = new DateTime(grpBegin, SWT.TIME);
		timeBegin.setLayoutData(BorderLayout.SOUTH);
		timeBegin.setEnabled(false);
		
		Group grpEnd = new Group(shlQueryTimeInterval, SWT.NONE);
		grpEnd.setLayoutData(new RowData(371, 205));
		grpEnd.setText("End");
		grpEnd.setLayout(new BorderLayout(0, 0));
		dateEnd = new DateTime(grpEnd, SWT.CALENDAR /*| SWT.DROP_DOWN*/);
		dateEnd.setLayoutData(BorderLayout.CENTER);
		dateEnd.setEnabled(false);
		timeEnd = new DateTime(grpEnd, SWT.TIME);
		timeEnd.setLayoutData(BorderLayout.SOUTH);
		timeEnd.setEnabled(false);
		
		btnEndDateOf = new Button(grpEnd, SWT.CHECK);
		btnEndDateOf.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				if(btnEndDateOf.getSelection()) {
					dateEnd.setEnabled(false);
					timeEnd.setEnabled(false);
				} else {
					dateEnd.setEnabled(true);
					timeEnd.setEnabled(true);
				}
			}
		});
		btnEndDateOf.setSelection(true);
		btnEndDateOf.setLayoutData(BorderLayout.NORTH);
		btnEndDateOf.setText("end date of data");
		
		Button btnOk = new Button(shlQueryTimeInterval, SWT.NONE);
		btnOk.setLayoutData(new RowData(378, SWT.DEFAULT));
		btnOk.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				buttonOK();
			}
		});
		btnOk.setText("OK");
		

	}
	
	private void buttonOK() {
		
		LocalDateTime begin = LocalDateTime.of(dateBegin.getYear(),dateBegin.getMonth(),dateBegin.getDay(),timeBegin.getHours(),timeBegin.getMinutes());
		LocalDateTime end = LocalDateTime.of(dateEnd.getYear(),dateEnd.getMonth(),dateEnd.getDay(),timeEnd.getHours(),timeEnd.getMinutes());
		result = new Pair<LocalDateTime, LocalDateTime>(begin, end); 
		
		shlQueryTimeInterval.close();
	}

}
