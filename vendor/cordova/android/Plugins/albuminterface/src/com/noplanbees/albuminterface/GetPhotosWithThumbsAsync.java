package com.noplanbees.albuminterface;
import org.apache.cordova.CallbackContext;

import android.content.Context;
import android.os.AsyncTask;


public class GetPhotosWithThumbsAsync extends AsyncTask<Void, Void, String>{
	private Context context;
	private int count;
	private int offset;
	private String[] albums;
	private Boolean includeAlbums;
	private CallbackContext callbackContext;
		
		
	public GetPhotosWithThumbsAsync(Context context, CallbackContext callbackContext, int count, int offset, String[] albums, Boolean includeAlbums ){
		super();
		this.context = context;
		this.count = count;
		this.offset = offset;
		this.albums = albums;
		this.includeAlbums = includeAlbums;
		this.callbackContext = callbackContext;
	}
		
	@Override
	protected String doInBackground(Void... params) {
		return AlbumInterface.getPhotosWithThumbsJson(context, offset, count, albums, includeAlbums);
	}
		
	protected void onPostExecute(String result){
//		 System.out.println(result);
		 callbackContext.success(result);
	}

}
