package com.noplanbees.albuminterface;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import org.json.JSONArray;
import org.json.JSONException;

import com.google.gson.Gson;
import com.noplanbees.utils.BitmapUtils;
import com.noplanbees.utils.CursorUtils;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.util.Log;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

public class AlbumInterface extends CordovaPlugin{

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

		Context context = cordova.getActivity().getApplicationContext();

		if ( action.equals("getThumbs") ) {
			int count = Integer.parseInt( args.getString(0) );
			int offset = Integer.parseInt( args.getString(1) );
			Cursor cursor = getThumbs(context, offset, count);
			String json = CursorUtils.cursorToJson(cursor);
			callbackContext.success(json);
			cursor.close();
			return true;
		}
		if ( action.equals("getPhotos") ) {
			int count = Integer.parseInt( args.getString(0) );
			int offset = Integer.parseInt( args.getString(1) );
			Cursor cursor = getPhotos(context, offset, count, null, null);
			String json = CursorUtils.cursorToJson(cursor);
			callbackContext.success(json);
			cursor.close();
			return true;
		}
		if ( action.equals("getPhotosWithThumbs") ) {
			int count = Integer.parseInt( args.getString(0) );
			int offset = Integer.parseInt( args.getString(1) );
			JSONArray jAlbums = args.getJSONArray(2);
			String[] albums = new String[jAlbums.length()];
			for ( int i =0; i < jAlbums.length() ; i++ )  {
				albums[i] = jAlbums.getString(i);
			}
			Boolean includeAlbums = args.getBoolean(3);
			GetPhotosWithThumbsAsync bg = new GetPhotosWithThumbsAsync(context, callbackContext, count, offset, albums,includeAlbums);
			bg.execute();
			return true;
		}
		if ( action.equals("getPhotoWithThumbById") ){
			String id = args.getString(0);
			Hashtable<String,String> photo_with_thumb = getPhotoWithThumbById(context, id);
			String json = CursorUtils.objectToJson(photo_with_thumb);
			callbackContext.success(json);
			return true;
		}
		if ( action.equals("getPhotoById") ){
			String id = args.getString(0);
			Cursor cursor = getPhotoById(context, id);
			String json = CursorUtils.cursorToJson(cursor);
			callbackContext.success(json);
			cursor.close();
			return true;
		}
		if ( action.equals("getAllPhotos") ) {
			Cursor cursor = getAllPhotos(context);
			String json = CursorUtils.cursorToJson(cursor);
			cursor.close();
			callbackContext.success(json);
		}
		return false;
	}

	public static String [] PHOTO_COLUMNS_API_16_PLUS = {
		MediaStore.Images.ImageColumns._ID,
		MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME,
		MediaStore.Images.ImageColumns.BUCKET_ID,
		MediaStore.Images.ImageColumns.HEIGHT,
		MediaStore.Images.ImageColumns.WIDTH,
		MediaStore.Images.ImageColumns.ORIENTATION,
		MediaStore.Images.ImageColumns.TITLE,
		MediaStore.Images.ImageColumns.DISPLAY_NAME,
		MediaStore.Images.ImageColumns.DESCRIPTION,
		MediaStore.Images.ImageColumns.DATE_TAKEN,
		MediaStore.Images.ImageColumns.DATE_ADDED,
		MediaStore.Images.ImageColumns.LATITUDE,
		MediaStore.Images.ImageColumns.LONGITUDE,
		MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC,
		MediaStore.Images.ImageColumns.DATA,
	};

	public static String [] PHOTO_COLUMNS_API_15_MINUS = {
		MediaStore.Images.ImageColumns._ID,
		MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME,
		MediaStore.Images.ImageColumns.BUCKET_ID,
		MediaStore.Images.ImageColumns.ORIENTATION,
		MediaStore.Images.ImageColumns.TITLE,
		MediaStore.Images.ImageColumns.DISPLAY_NAME,
		MediaStore.Images.ImageColumns.DESCRIPTION,
		MediaStore.Images.ImageColumns.DATE_TAKEN,
		MediaStore.Images.ImageColumns.DATE_ADDED,
		MediaStore.Images.ImageColumns.LATITUDE,
		MediaStore.Images.ImageColumns.LONGITUDE,
		MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC,
		MediaStore.Images.ImageColumns.DATA,
	};

	public static String [] THUMB_COLUMNS = {
		MediaStore.Images.Thumbnails._ID,
		MediaStore.Images.Thumbnails.IMAGE_ID,
		MediaStore.Images.Thumbnails.KIND,
		MediaStore.Images.Thumbnails.DEFAULT_SORT_ORDER,
		MediaStore.Images.Thumbnails.HEIGHT,
		MediaStore.Images.Thumbnails.WIDTH,
		MediaStore.Images.Thumbnails.DATA,
	};

	private static String [] photoColumns() {
		if (android.os.Build.VERSION.SDK_INT > 15) {
			return PHOTO_COLUMNS_API_16_PLUS;
		} else {
			return PHOTO_COLUMNS_API_15_MINUS;
		}    
	}

	public static Cursor getThumbs(Context context, int offset, int count) {

		String sort_order = MediaStore.Images.Thumbnails.IMAGE_ID + " DESC ";
		if (count > 0){sort_order += " LIMIT " + count;}
		if (count > 0 && offset > 0){sort_order += " OFFSET " + offset;}

		Cursor cursor = context.getContentResolver().query(
				MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI, 
				THUMB_COLUMNS, 
				null, 
				null, 
				sort_order
				);
		return cursor;
	}

	public static Cursor getAllThumbs(Context context){
		return getThumbs(context, -1, -1);
	}

	public static Cursor getThumbByImageId(Context context, String id){
		//	Forces the thumbnail queried for later to be created if it has not been already.	
		ContentResolver cr = context.getContentResolver();
		Bitmap bmp = MediaStore.Images.Thumbnails.getThumbnail(cr, Long.valueOf(id), MediaStore.Images.Thumbnails.MINI_KIND, null);

		if (bmp == null){ 
			Log.e("AlbumInterface.getThumbsByImageId", "Null returned for getThumbnail: " + id);
			return null; 
		}
		Cursor cursor = MediaStore.Images.Thumbnails.queryMiniThumbnail(context.getContentResolver(), Long.valueOf(id), MediaStore.Images.Thumbnails.MINI_KIND, THUMB_COLUMNS);
		//		String[] args = {id};
		//		Cursor cursor = context.getContentResolver().query(
		//				MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI, 
		//				THUMB_COLUMNS, 
		//				MediaStore.Images.Thumbnails.IMAGE_ID + " = ? ", 
		//				args, 
		//				null);
		return cursor;
	}

	public static Bitmap getThumbBitmap(Context context, String id){
		ContentResolver cr = context.getContentResolver();
		Bitmap bmp = MediaStore.Images.Thumbnails.getThumbnail(cr, Long.valueOf(id), MediaStore.Images.Thumbnails.MICRO_KIND, null);
		return bmp;
	}

	public static Cursor getPhotos(Context context, int offset, int count, String[] albums, Boolean includeAlbums) {    
		String sort_order = MediaStore.Images.ImageColumns.DATE_TAKEN + " DESC ";
		if (count > 0){sort_order += " LIMIT " + count;}
		if (count > 0 && offset > 0){sort_order += " OFFSET " + offset;}

		String selection = null;
		if ( albums != null && albums.length > 0 ) {
			String operator = includeAlbums ? " IN " : " NOT IN ";
			StringBuilder list = new StringBuilder();
			for ( String s: albums ) {
				list.append("'").append(s).append("'").append(",");
			}
			list.delete(list.length()-1,list.length());
			selection = MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME + operator + "(" + list.toString() + ")"; 
		}

		Cursor cursor = context.getContentResolver().query(
				MediaStore.Images.Media.EXTERNAL_CONTENT_URI, 
				photoColumns(), 
				selection, 
				null, 
				sort_order
				);
		return cursor;
	}

	public static Cursor getAllPhotos(Context context) {
		String[] albums = {};
		Cursor cursor = getPhotos(context, -1, -1, albums, true);
		return cursor;
	}

	public static Cursor getPhotoById(Context context, String id) {    	
		String selection = MediaStore.Images.ImageColumns._ID + " = " + id;
		Cursor cursor = context.getContentResolver().query(
				MediaStore.Images.Media.EXTERNAL_CONTENT_URI, 
				photoColumns(),
				selection, 
				null, 
				null
				);
		return cursor;    	
	}

	public static ArrayList<Hashtable<String,String>> getPhotosWithThumbs(Context context, int offset, int count, String[] albums, Boolean includeAlbums){
		long java_start_time = System.currentTimeMillis();

		Cursor photos_cursor = getPhotos(context, offset, count, albums, includeAlbums);
		ArrayList<Hashtable<String, String>> photos_array = CursorUtils.cursorToArrayOfHashes(photos_cursor);

		if (photos_cursor == null){return photos_array;}

		for(Hashtable<String,String> photo_hash : photos_array){
			if (addThumbHashToPhotoHash(context,photo_hash)  == null){
			  addThumbBmpToPhotoHash(context, photo_hash);
			}
		}
		photos_cursor.close();
		photos_array.get(0).put("java_time", "" + (System.currentTimeMillis() - java_start_time));
		return photos_array;
	}

	public static String getPhotosWithThumbsJson(Context context, int offset, int count, String[] albums, Boolean includeAlbums){
		ArrayList<Hashtable<String, String>> a = getPhotosWithThumbs(context, offset, count, albums, includeAlbums);
		return CursorUtils.objectToJson(a);
	}

	private static Hashtable<String,String> addThumbHashToPhotoHash(Context context, Hashtable<String,String> photo_hash){
		String image_id = photo_hash.get("_id");
		Cursor thumb_cursor = getThumbByImageId(context, image_id);

		if (thumb_cursor == null || thumb_cursor.getCount() == 0){
			Log.e("AlbumInterface.getPhotosWithThumbs", "No thumb found for image_id: " + image_id);
			if (thumb_cursor != null){ thumb_cursor.close(); }
			return null;
		}
		thumb_cursor.moveToNext();
		Hashtable<String, String> thumb_hash = CursorUtils.cursorCurrentPositionToHash(thumb_cursor);
		thumb_cursor.close();
		thumb_hash = prefixThumbColumnNames(thumb_hash);
		photo_hash.putAll(thumb_hash);
		return photo_hash;
	}
	
	private static Hashtable<String, String> addThumbBmpToPhotoHash(Context context, Hashtable<String, String> photo_hash){
		String image_id = photo_hash.get("_id");
		Bitmap bmp = getThumbBitmap(context, image_id);
		if (bmp == null){
			return photo_hash;
		} else {
			String bmp_64 = BitmapUtils.BitmapToBase64(bmp);
			photo_hash.put("thumb_bmp", bmp_64);
			return photo_hash;
		}
	}

	public static Hashtable<String, String> getPhotoWithThumbById(Context context, String id){
		Cursor cursor = getPhotoById(context, id);
		Hashtable<String,String> photo_hash = new Hashtable<String, String>();
		if (cursor == null){return photo_hash;}

		cursor.moveToFirst();
		photo_hash = CursorUtils.cursorCurrentPositionToHash(cursor);
		addThumbHashToPhotoHash(context, photo_hash);
		return photo_hash; 
	}

	public static Hashtable<String, String> prefixThumbColumnNames(Hashtable<String,String> thumb_hash){
		Enumeration<String> thumb_keys = thumb_hash.keys();
		Hashtable<String,String> prefixed_thumb_hash = new Hashtable<String, String>();

		while(thumb_keys.hasMoreElements()){
			String thumb_key = thumb_keys.nextElement();
			String value = thumb_hash.get(thumb_key);
			prefixed_thumb_hash.put("thumb_" + thumb_key, value);
		}
		return prefixed_thumb_hash;
	}


}

