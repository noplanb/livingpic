package com.noplanbees.utils;

import java.util.Enumeration;
import java.util.Hashtable;

import android.content.Context;
import android.database.Cursor;
import android.provider.MediaStore;
import android.util.Log;

import com.noplanbees.albuminterface.AlbumInterface;

public class MediaStoreTest {
	
	// This led me to discover how to properly bring in the thumbs. See AlbumInterface.txt   
	public static void thumbsWithPhotos(Context context){
		// Get all the thumbs. Figure out how many have photos associated with them.

		int num_photos;
		int num_thumbs;
		int num_thumbs_w_photos = 0;
		int num_thumbs_w_out_photos = 0;
		
        System.out.println("MediaStoreTest.thumbsWithPhotos starting");

		Cursor thumb_cursor = AlbumInterface.getThumbs(context, -1, -1);
		num_thumbs = thumb_cursor.getCount();
        System.out.println("Got thumbs: " + num_thumbs);
        
		Cursor all_photos_cursor = AlbumInterface.getPhotos(context, -1, -1, null, null);
		num_photos = all_photos_cursor.getCount();
        System.out.println("Got photos: " + num_photos);
        
        all_photos_cursor.close();
		
		thumb_cursor.moveToFirst();
		while(!thumb_cursor.isAfterLast()){
			int columnIndex = thumb_cursor.getColumnIndex("image_id");
			String image_id = thumb_cursor.getString(columnIndex);
			Cursor photo_cursor = AlbumInterface.getPhotoById(context, image_id);
			if (photo_cursor.getCount() > 0){
				num_thumbs_w_photos++;
			} else {
				num_thumbs_w_out_photos++; 
			}
			photo_cursor.close();
			thumb_cursor.moveToNext();
		}
		thumb_cursor.close();
		
		System.out.println("Total Photos: " + num_photos);
		System.out.println("Total Thumbs: " + num_thumbs);
		System.out.println("Thumbs with photos: " + num_thumbs_w_photos);
		System.out.println("Thumbs without photos: " + num_thumbs_w_out_photos);
	}
	

	
	public static void postAllPhotosToServer(Context context){
    	Log.d("postAllPhotosToServer", "Started");

//		ArrayList<Hashtable<String, String>> all_photos_array = AlbumInterface.getPhotosWithThumbs(context, -1, -1);
//    	Log.d("postAllPhotosToServer", "got photos: " + all_photos_array.toArray().length);
//
//		String all_photos_json = CursorUtils.objectToJson(all_photos_array);
		
		Cursor photos_cursor = AlbumInterface.getAllPhotos(context);
	    Cursor thumbs_cursor = AlbumInterface.getAllThumbs(context);
		
//		String id = 1530 + "";
//		Cursor photo_cursor = AlbumInterface.getPhotoById(context, id);
//		String photo_json = CursorUtils.cursorToJson(photo_cursor);
				
		new PostToWeb().execute("http://192.168.1.65:3000/admin/stats/post_all_photos_data", CursorUtils.cursorToJson(photos_cursor));
		new PostToWeb().execute("http://192.168.1.65:3000/admin/stats/post_thumb_data", CursorUtils.cursorToJson(thumbs_cursor));
	}
    
	public static void photoStatsByBucket(Context context) {
		Cursor cursor = AlbumInterface.getAllPhotos(context);
		Hashtable<String, Integer> buckets = new Hashtable<String, Integer>();
		cursor.moveToFirst();
		String column_name = MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME;
		int column_index = cursor.getColumnIndex(column_name);
		while (!cursor.isAfterLast()){
			String bucket = cursor.getString(column_index);
			if ( buckets.containsKey(bucket) ){
				int val = buckets.get(bucket);
				buckets.put(bucket, val + 1);
			} else {
				buckets.put(bucket, 1);
			}
			cursor.moveToNext();
		}
		cursor.close();
		
		Enumeration<String> bucket_names = buckets.keys();
		while (bucket_names.hasMoreElements()) {
			String name = bucket_names.nextElement();
			System.out.println(name + " " + buckets.get(name));
		}
	}
	
	
}