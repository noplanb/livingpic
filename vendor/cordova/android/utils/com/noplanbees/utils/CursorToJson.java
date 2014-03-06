package com.noplanbees.utils;

import java.util.ArrayList;
import java.util.Hashtable;

import com.google.gson.Gson;

import android.database.Cursor;

public class CursorToJson {

	public static String to_json(Cursor cursor) {
		cursor.moveToFirst();
		ArrayList a = new ArrayList();
		String value;

		while(!cursor.isAfterLast()){
			Hashtable h = new Hashtable();
			for (int i=0; i < cursor.getColumnCount(); i++){
				String column_name = cursor.getColumnNames()[i];
				int column_index = cursor.getColumnIndex(column_name);
				if (column_index < 0) {continue;} 
				if (cursor.getString(column_index) == null){
					value = "null";
				} else {
					value = cursor.getString(column_index);
				}
				h.put(column_name, value);
			}
			a.add(h);
			cursor.moveToNext();
		}
		Gson gson = new Gson();
		String result = gson.toJson(a);
		return result;
	}

}
