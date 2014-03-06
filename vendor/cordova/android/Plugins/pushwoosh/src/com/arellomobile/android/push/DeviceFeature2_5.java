//
//  DeviceFeature2_5.java
//
// Pushwoosh Push Notifications SDK
// www.pushwoosh.com
//
// MIT Licensed
package com.arellomobile.android.push;

import android.content.Context;
import android.location.Location;
import android.util.Log;
import com.arellomobile.android.push.data.PushZoneLocation;
import com.arellomobile.android.push.request.RequestHelper;
import com.arellomobile.android.push.utils.NetworkUtils;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Date: 16.08.12
 * Time: 19:04
 *
 * @author mig35
 */
public class DeviceFeature2_5
{
	private static final String TAG = "PushWoosh DeviceFeature2_5";

	private static final String PUSH_STAT = "pushStat";
	private static final String TAGS_PATH = "setTags";
	private static final String NEAREST_ZONE = "getNearestZone";
	private static final String APP_OPEN = "applicationOpen";
	private static final String MSG_DELIVERED = "messageDeliveryEvent";
	private static final String PACKAGE_REMOVED = "androidPackageRemoved";
	private static final String GOAL_ACHIEVED = "applicationEvent";

	public static void sendPushStat(Context context, String hash)
	{
		if(hash == null)
			return;
		
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getSendPushStatData(context, hash, NetworkUtils.PUSH_VERSION));

		Log.w(TAG, "Try To sent PushStat");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, PUSH_STAT);
				if (200 == res.getResultCode())
				{
					Log.w(TAG, "Send PushStat success");
					return;
				}
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: Try To sent PushStat " + exception.getMessage() + ". Response = " + res.getResultData(),
				exception);
	}
	
	public static void sendGoalAchieved(Context context, String goal, Integer count)
	{
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getSendGoalAchievedData(context, goal, count, NetworkUtils.PUSH_VERSION));

		Log.w(TAG, "Try To sent Goal");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, GOAL_ACHIEVED);
				if (200 != res.getResultCode())
					continue;
				
				if (200 != res.getPushwooshCode())
					break;

				Log.w(TAG, "Send Goal success");
				return;
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: Try To sent PushStat " + exception.getMessage() + ". Response = " + res.getResultData(),
				exception);
	}
	
	public static void sendAppOpen(Context context)
	{
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getSendAppOpenData(context, NetworkUtils.PUSH_VERSION));

		Log.w(TAG, "Try To sent AppOpen");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, APP_OPEN);
				if (200 != res.getResultCode())
					continue;
				
				if (200 != res.getPushwooshCode())
					break;

				Log.w(TAG, "Send AppOpen success");
				return;
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: Try To sent AppOpen " + exception.getMessage() + ". Response = " + res.getResultData(),
				exception);
	}

	public static JSONArray sendTags(Context context, Map<String, Object> tags) throws Exception
	{
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getSendTagsData(context, NetworkUtils.PUSH_VERSION));

		JSONObject tagsObject = new JSONObject();
		for (String key : tags.keySet())
		{
			Object value = tags.get(key);
			if (value instanceof String || value instanceof Integer)
			{
				tagsObject.put(key, value);
			}
			else if (value instanceof List)
			{
				JSONArray values = new JSONArray();
				for (Object item : (List<?>) value)
				{
					if (item instanceof String || item instanceof Integer)
					{
						values.put(String.valueOf(item));
					}
					else
					{
						throw new RuntimeException("wrong type for tag: " + key);
					}
				}
				tagsObject.put(key, values);
			}
			else if (value instanceof JSONArray)
			{
				JSONArray values = (JSONArray)value;
				tagsObject.put(key, values);
			}
			else
			{
				throw new RuntimeException("wrong type for tag: " + key);
			}
		}

		data.put("tags", tagsObject);

		Log.w(TAG, "Try To sent Tags");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, TAGS_PATH);
				if (200 != res.getResultCode())
					continue;
				
				if (200 != res.getPushwooshCode())
					break;

				Log.w(TAG, "Send Tags success");
				JSONObject response = res.getResultData().getJSONObject("response");
				if(response == null)
					return new JSONArray();
				
				return response.getJSONArray("skipped");
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: sent Tags " + exception.getMessage() + ". Response = " + res, exception);
		throw exception;
	}

	public static PushZoneLocation getNearestZone(Context context, Location location) throws Exception
	{
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getNearestZoneData(context, location, NetworkUtils.PUSH_VERSION));

		Log.w(TAG, "Try To Sent Nearest Zone");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, NEAREST_ZONE);
				if (200 != res.getResultCode())
					continue;
				
				if (200 != res.getPushwooshCode())
					break;

				Log.w(TAG, "Send Nearest Zone success");

				return RequestHelper.getPushZoneLocationFromData(res.getResultData(), NetworkUtils.PUSH_VERSION);
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: sent Nearest Zone " + exception.getMessage() + ". Response = " + res, exception);
		throw exception;
	}
	
	public static void sendMessageDeliveryEvent(Context context, String hash)
	{
		if(hash == null)
			return;
		
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getSendPushStatData(context, hash, NetworkUtils.PUSH_VERSION));

		Log.w(TAG, "Try To sent MsgDelivered");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, MSG_DELIVERED);
				if (200 != res.getResultCode())
					continue;
				
				if (200 != res.getPushwooshCode())
					break;

				Log.w(TAG, "Send MsgDelivered success");
				return;
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: Try To sent MsgDelivered " + exception.getMessage() + ". Response = " + res.getResultData(),
				exception);
	}
	
	static void sendAppRemovedData(Context context, String packageName)
	{
		final Map<String, Object> data = new HashMap<String, Object>();

		data.putAll(RequestHelper.getAppRemovedData(context, packageName, NetworkUtils.PUSH_VERSION));

		Log.w(TAG, "Try To sent AppRemoved");

		NetworkUtils.NetworkResult res = new NetworkUtils.NetworkResult(500, 0, null);
		Exception exception = new Exception();
		for (int i = 0; i < NetworkUtils.MAX_TRIES; ++i)
		{
			try
			{
				res = NetworkUtils.makeRequest(data, PACKAGE_REMOVED);
				if (200 != res.getResultCode())
					continue;
				
				if (200 != res.getPushwooshCode())
					break;

				Log.w(TAG, "Send AppRemoved success");
				return;
			}
			catch (Exception e)
			{
				exception = e;
			}
		}

		Log.e(TAG, "ERROR: Try To sent AppRemoved " + exception.getMessage() + ". Response = " + res.getResultData(),
				exception);
	}
}
