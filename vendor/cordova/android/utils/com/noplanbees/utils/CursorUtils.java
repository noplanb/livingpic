package com.noplanbees.utils;

import java.util.ArrayList;
import java.util.Hashtable;

import android.database.Cursor;

import com.google.gson.Gson;

public class CursorUtils {

	public static String cursorToJson(Cursor cursor) {
		return objectToJson(cursorToArrayOfHashes(cursor));
	}

	public static ArrayList<Hashtable<String, String>> cursorToArrayOfHashes(Cursor cursor) {
		ArrayList<Hashtable<String, String>> a = new ArrayList<Hashtable<String, String>>();

		if (cursor == null) {return a;}

		cursor.moveToFirst();
		while (!cursor.isAfterLast()) {
			Hashtable<String, String> h = cursorCurrentPositionToHash(cursor);
			a.add(h);
			cursor.moveToNext();
		}
		return a;
	}
	
	public static Hashtable<String, String> cursorCurrentPositionToHash(Cursor cursor){
		Hashtable<String, String> h = new Hashtable<String, String>();
		
		if (cursor == null) {return h;}
		
		String value;
		for (int i = 0; i < cursor.getColumnCount(); i++) {
			String column_name = cursor.getColumnNames()[i];
			int column_index = cursor.getColumnIndex(column_name);
			if (column_index < 0) {
				continue;
			}
			if (cursor.getString(column_index) == null) {
				value = "null";
			} else {
				value = cursor.getString(column_index);
			}
			h.put(cursor.getColumnNames()[i], value);
		}
		return(h);
	}
	
	public static String objectToJson(Object obj) {
		Gson gson = new Gson();
		return gson.toJson(obj);
	}

}
