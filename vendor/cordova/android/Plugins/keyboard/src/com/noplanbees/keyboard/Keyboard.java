package com.noplanbees.keyboard;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.apache.cordova.CallbackContext;

import android.content.Context;
import android.view.inputmethod.InputMethodManager;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class shows and hides the keyboard explicitly
 */
public class Keyboard extends CordovaPlugin {
    public Keyboard() {
    }

    public void showKeyBoard() {
      InputMethodManager mgr = (InputMethodManager) cordova.getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
      mgr.showSoftInput(webView, InputMethodManager.SHOW_IMPLICIT);
    
      ((InputMethodManager) cordova.getActivity().getSystemService(Context.INPUT_METHOD_SERVICE)).showSoftInput(webView, 0); 
    }
  
    public void hideKeyBoard() {
      InputMethodManager mgr = (InputMethodManager) cordova.getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
      mgr.hideSoftInputFromWindow(webView.getWindowToken(), 0);
    }
  
    public boolean isKeyBoardShowing() {
      int heightDiff = webView.getRootView().getHeight() - webView.getHeight();
      return (100 < heightDiff); // if more than 100 pixels, its probably a keyboard...
    }
  
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("echo")) {
            String message = args.getString(0);
            this.echo(message, callbackContext);
            return true;
        }
        else if (action.equals("show")) {
            this.showKeyBoard();
            callbackContext.success("shown");
            return true;
        } 
        else if (action.equals("hide")) {
            this.hideKeyBoard();
            callbackContext.success("hidden");
            return true;
        }
        else if (action.equals("isShowing")) {                        
            callbackContext.success(Boolean.toString(this.isKeyBoardShowing()));
            return true;
        }
        return false;
    }

    private void echo(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }
}
