package com.gamestamper.graph {

  import com.adobe.serialization.json.JSON;
  import com.adobe.serialization.json.JSONParseError;
  import com.gamestamper.graph.core.AbstractGamestamper;
  import com.gamestamper.graph.core.GamestamperJSBridge;
  import com.gamestamper.graph.core.GamestamperURLDefaults;
  import com.gamestamper.graph.data.GamestamperSession;
  import com.gamestamper.graph.net.GamestamperRequest;

  import com.hurlant.util.Base64;
  
  import flash.external.ExternalInterface;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.net.navigateToURL;
  import flash.utils.Dictionary;

  public class Gamestamper extends AbstractGamestamper {

    /**
     * @private
     *
     */
    protected var jsCallbacks:Object;
	
	/**
	 * @private
	 *
	 */
	protected var openUICalls:Dictionary;
	
	/**
	 * @private
	 *
	 */
	protected var jsBridge:GamestamperJSBridge;

    /**
     * @private
     *
     */
    protected var applicationId:String;

    /**
     * @private
     *
     */
    protected static var _instance:Gamestamper;

    /**
     * @private
     *
     */
    protected static var _canInit:Boolean = false;

    /**
     * @private
     *
     */
    protected var _initCallback:Function;

    /**
     * @private
     *
     */
    protected var _loginCallback:Function;

    /**
     * @private
     *
     */
    protected var _logoutCallback:Function;

    /**
     * Creates an instance of Gamestamper.
     *
     */
    public function Gamestamper() {
      super();

      if (_canInit == false) {
        throw new Error(
          'Gamestamper is an singleton and cannot be instantiated.'
        );
      }
	  
	  jsBridge = new GamestamperJSBridge(); //create an instance

      jsCallbacks = {};
	  
	  openUICalls = new Dictionary();
    }

    //Public API
    /**
     * Initializes this Gamestamper singleton with your Application ID.
     * You must call this method first.
     *
     * @param applicationId The application ID you created at
     * http://www.gamestamper.com/developers/apps.php
     *
     * @param callback (Optional)
	 * Method to call when initialization is complete.
     * The handler must have the signature of callback(success:Object, fail:Object);
     * Success will be a GamestamperSession if successful, or null if not.
     *
     * @param options (Optional)
     * Object of options used to instantiate the underling Javascript SDK
	 * 
	 * @param accessToken (Optional)
     * A valid Gamestamper access token. If you have a previously saved access token, you can pass it in here.
     *
     * @see http://developers.gamestamper.com/docs/reference/javascript/FB.init
     *
     */
    public static function init(applicationId:String,
                  callback:Function = null,
                  options:Object = null,
				  accessToken:String = null
    ):void {

      getInstance().init(applicationId, callback, options, accessToken);
    }

	/**
	*	Takes the encoded signedRequest string and decodes it into a JSON object
	*
	*/
	public static function decodeSignedRequest(signedRequest:String):Object {
		var v:Object = signedRequest.split('.');
		var payload:String = Base64.decode(v[1]);
		return JSON.decode(payload);
	}

   /**
     * Shows the Gamestamper login window to the end user.
     *
     * @param callback The method to call when login is successful.
     * The handler must have the signature of callback(success:Object, fail:Object);
     * Success will be a GamestamperSession if successful, or null if not.
     *
     * @param options Values to modify the behavior of the login window.
     * http://developers.gamestamper.com/docs/reference/javascript/FB.login
     *
     */
    public static function login(callback:Function, options:Object = null):void {
      getInstance().login(callback, options);
    }

    /**
     * Re-directs the user to a mobile-friendly login form.
     *
     * @param redirectUri After a successful login,
     * Gamestamper will redirect the user back to this URL,
     * where the underlying Javascript SDK will notify this swf
     * that a valid login has occurred.
     *
     * @param display Type of login form to show to the user.
     * <ul>
     *	<li>touch Default; (Recommended)
     * 		Smartphone, full featured web browsers.
     * 	</li>
     *
     *	<li>wap;
     *		Older mobile web browsers,
     * 		shows a slimmer UI to the end user.
     * 	</li>
     * </ul>
	 * 
	 * @param extendedPermissions (Optional) Array of extended permissions
     * to ask the user for once they are logged in.
     *
     * @see http://developers.gamestamper.com/docs/guides/mobile/
     *
     */
    public static function mobileLogin(redirectUri:String,
                       display:String = 'touch',
					   extendedPermissions:Array = null
    ):void {

      var data:URLVariables = new URLVariables();
      data.client_id = getInstance().applicationId;
      data.redirect_uri = redirectUri;
      data.display = display;	  
	  if (extendedPermissions != null) { data.scope = extendedPermissions.join(","); }

      var req:URLRequest = new URLRequest(GamestamperURLDefaults.AUTH_URL);
      req.method = URLRequestMethod.GET;
      req.data = data;

      navigateToURL(req, '_self');
    }
	
	/**
	 * Logs the user out after being logged in with mobileLogin().
	 *
	 * @param redirectUri After logout, Gamestamper will redirect
	 * the user back to this URL.
	 *
	 */
	public static function mobileLogout(redirectUri:String):void {
		getInstance().session = null;
		
		var data:URLVariables = new URLVariables();
		data.confirm = 1;
		data.next = redirectUri;	
		
		var req:URLRequest = new URLRequest("http://www.gamestamper.com/logout.php");
		req.method = URLRequestMethod.GET;
		req.data = data;
		
		navigateToURL(req, '_self');				
	}

    /**
     * Logs the user out of their current session.
     *
     * @param callback Method to call when logout is complete.
     *
     */
    public static function logout(callback:Function):void {
      getInstance().logout(callback);
    }

    /**
     * Shows a Gamestamper sharing dialog.
     *
     * @param method The related method for this dialog
     *	(ex. stream.publish).
     * @param data Data to pass to the dialog, date will be JSON encoded.
	 * @param callback (Optional) Method to call when complete
     * @param display (Optional) The type of dialog to show (iframe or popup).
     * @see http://developers.gamestamper.com/docs/reference/javascript/FB.ui
     *
     */
    public static function ui(method:String,
                    data:Object,
					callback:Function=null,
                    display:String=null
       ):void {

      getInstance().ui(method, data, callback, display);
    }

    /**
     * Makes a new request on the Gamestamper Graph API.
     *
     * @param method The method to call on the Graph API.
     * For example, to load the user's current friends, pass: /me/friends
     *
     * @param calllback Method that will be called when this request is complete
     * The handler must have the signature of callback(result:Object, fail:Object);
     * On success, result will be the object data returned from Gamestamper.
     * On fail, result will be null and fail will contain information about the error.
     *
     * @param params Any parameters to pass to Gamestamper.
     * For example, you can pass {file:myPhoto, message:'Some message'};
     * this will upload a photo to Gamestamper.
     * @param requestMethod
     * The URLRequestMethod used to send values to Gamestamper.
     * The graph API follows correct Request method conventions.
     * GET will return data from Gamestamper.
     * POST will send data to Gamestamper.
     * DELETE will delete an object from Gamestamper.
     *
     * @see flash.net.URLRequestMethod
     * @see http://developers.gamestamper.com/docs/api
     *
     */
    public static function api(method:String,
                     callback:Function = null,
                     params:* = null,
                     requestMethod:String = 'GET'
    ):void {

      return getInstance().api(method,
        callback,
        params,
        requestMethod
      );
    }

    /**
     * Shortcut method to post data to Gamestamper.
     * Alternatively,
     * you can call Gamestamper.request and use POST for requestMethod.
     *
     * @see com.gamestamper.graph.net.Gamestamper#api()
     */
    public static function postData(
      method:String,
      callback:Function = null,
      params:Object = null
    ):void {

      api(method, callback, params, URLRequestMethod.POST);
    }

    /**
     * Executes an FQL query on api.gamestamper.com.
     *
     * @param query The FQL query string to execute.
     * @see http://developers.gamestamper.com/docs/reference/fql/
     * @see com.gamestamper.graph.net.Gamestamper#callRestAPI()
     *
     */
    public static function fqlQuery(query:String, callback:Function):void {
      getInstance().fqlQuery(query, callback);
    }

    /**
     * Used to make old style RESTful API calls on Gamestamper.
     * Normally, you would use the Graph API to request data.
     * This method is here in case you need to use an old method,
     * such as FQL.
     *
     * @param methodName Name of the method to call on api.gamestamper.com
     * (ex, fql.query).
     * @param values Any values to pass to this request.
     * @param requestMethod URLRequestMethod used to send data to Gamestamper.
     *
     */
    public static function callRestAPI(methodName:String,
                       callback:Function,
                       values:* = null,
                       requestMethod:String = 'GET'
    ):void {

      return getInstance().callRestAPI(methodName, callback, values, requestMethod);
    }

    /**
     * Utility method to format a picture URL,
     * in order to load an image from Gamestamper.
     *
     * @param id The ID you wish to load an image from.
     * @param type The size of image to display from Gamestamper
     * (square, small, or large).
     *
     * @see http://developers.gamestamper.com/docs/api#pictures
     *
     */
    public static function getImageUrl(id:String,
                       type:String = null
    ):String {

      return getInstance().getImageUrl(id, type);
    }

    /**
     * Deletes an object from Gamestamper.
     * The current user must have granted extended permission
     * to delete the corresponding object,
     * or an error will be returned.
     *
     * @param method The ID and connection of the object to delete.
     * For example, /POST_ID/like to remove a like from a message.
     *
     * @see http://developers.gamestamper.com/docs/api#deleting
     * @see com.gamestamper.graph.net.GamestamperDesktop#api()
     *
     */
    public static function deleteObject(method:String, callback:Function = null):void {
      getInstance().deleteObject(method, callback);
    }

    /**
     * Utility method to add listeners to the underlying Gamestamper library.
     * @param event Name of the Javascript event to listen for.
     * @param listener Name of function to call when event is fired.
     *
     * This method will need to accept an optional result:Object,
     * that will be the decoded JSON result, if one exists.
     *
     * @see http://developers.gamestamper.com/docs/reference/javascript/FB.Event.subscribe
     *
     */
    public static function addJSEventListener(event:String,
                          listener:Function
    ):void {

      getInstance().addJSEventListener(event, listener);
    }

    /**
     * Removes a Javascript event listener,
     * added by Gamestamper.addJSEventListener();
     *
     * @see #addJSEventListener();
     *
     */
    public static function removeJSEventListener(event:String,
                           listener:Function
    ):void {

      getInstance().removeJSEventListener(event, listener);
    }

    /**
     * Checks to see if a specified event listener exists.
     *
     */
    public static function hasJSEventListener(event:String,
                          listener:Function
    ):Boolean {

      return getInstance().hasJSEventListener(event, listener);
    }

    /**
     * @see http://developers.gamestamper.com/docs/reference/javascript/FB.Canvas.setAutoResize
     *
     */
    public static function setCanvasAutoResize(autoSize:Boolean = true,
                           interval:uint = 100
    ):void {

      getInstance().setCanvasAutoResize(autoSize, interval);
    }

    /**
     * @see http://developers.gamestamper.com/docs/reference/javascript/FB.Canvas.setSize
     *
     */
    public static function setCanvasSize(width:Number, height:Number):void {
      getInstance().setCanvasSize(width, height);
    }

    /**
     * Calls an arbitrary Javascript method on the underlying HTML page.
     *
     */
    public static function callJS(methodName:String, params:Object):void {
      getInstance().callJS(methodName, params);
    }

    /**
     * Synchronous method to retrieve the current user's session.
     *
     */
    public static function getSession():GamestamperSession {
      return getInstance().getSession();
    }

    /**
    * Asynchronous method to get the user's current session from Gamestamper.
    *
    * This method calls out to the underlying Javascript SDK
    * to check what the current user's login status is.
    * You can listen for a javscript event by using
    * Gamestamper.addJSEventListener('auth.sessionChange', callback)
    * @see http://developers.gamestamper.com/docs/reference/javascript/FB.getLoginStatus
    *
    */
    public static function getLoginStatus():void {
      getInstance().getLoginStatus();
    }

    //Protected methods
    /**
     * @private
     *
     */
    protected function init(applicationId:String,
              callback:Function = null,
              options:Object = null,
			  accessToken:String = null
    ):void {
		
      ExternalInterface.addCallback('handleJsEvent', handleJSEvent);
      ExternalInterface.addCallback('sessionChange', handleSessionChange);
	  ExternalInterface.addCallback('logout', handleLogout);
	  ExternalInterface.addCallback('uiResponse', handleUI);

      _initCallback = callback;
	  
      this.applicationId = applicationId;

      if (options == null) { options = {};}
      options.appId = applicationId;
	  
      ExternalInterface.call('FBAS.init', JSON.encode(options));
	  
	  if (accessToken != null) {		  
		  session = new GamestamperSession();
		  session.accessToken = accessToken;		  
	  }

      getLoginStatus();
	  
    }

    /**
     * @private
     *
     */
    protected function getLoginStatus():void {
      ExternalInterface.call('FBAS.getLoginStatus');
    }

    /**
     * @private
     *
     */
    protected function callJS(methodName:String, params:Object):void {
      ExternalInterface.call(methodName, params);
    }

    /**
     * @private
     *
     */
    protected function setCanvasSize(width:Number, height:Number):void {
      ExternalInterface.call('FBAS.setCanvasSize', width, height);
    }

    /**
     * @private
     *
     */
    protected function setCanvasAutoResize(autoSize:Boolean = true,
                         interval:uint = 100
    ):void {

      ExternalInterface.call('FBAS.setCanvasAutoResize',
        autoSize,
        interval
      );
    }

    /**
     * @private
     *
     */
    protected function login(callback:Function, options:Object = null):void {
      _loginCallback = callback;

      ExternalInterface.call('FBAS.login', JSON.encode(options));
    }

    /**
     * @private
     *
     */
    protected function logout(callback:Function):void {
      _logoutCallback = callback;      
      ExternalInterface.call('FBAS.logout');
    }

    /**
     * @private
     *
     */
    protected function getSession():GamestamperSession {
      var result:String = ExternalInterface.call('FBAS.getSession');
      var sessionObj:Object;

      try {
        sessionObj = JSON.decode(result);
      } catch (e:*) {
        return null;
      }

      var s:GamestamperSession = new GamestamperSession();
      s.fromJSON(sessionObj);
      this.session = s;

      return session;
    }

    /**
     * @private
     *
     */
    protected function ui(method:String,
                  data:Object,
				  callback:Function=null,
                  display:String=null
    ):void {

      data.method = method;

	  if (callback != null) {
		  openUICalls[method] = callback;
	  }
	  
      if (display) {
        data.display = display;
      }

      ExternalInterface.call('FBAS.ui', JSON.encode(data));
    }

    /**
     * @private
     *
     */
    protected function addJSEventListener(event:String,
                        listener:Function
    ):void {

      if (jsCallbacks[event] == null) {
        jsCallbacks[event] = new Dictionary();
        ExternalInterface.call('FBAS.addEventListener', event);
      }

      jsCallbacks[event][listener] = null;
    }

    /**
     * @private
     *
     */
    protected function removeJSEventListener(event:String,
                         listener:Function
    ):void {

      if (jsCallbacks[event] == null) { return; }

      delete jsCallbacks[event][listener];
    }

    /**
     * @private
     *
     */
    protected function hasJSEventListener(event:String,
                        listener:Function
    ):Boolean {

      if (jsCallbacks[event] == null
        || jsCallbacks[event][listener] !== null
      ) {
        return false;
      }

      return true;
    }
	
	/**
	 * @private
	 *
	 */
	protected function handleUI( result:String, method:String ):void {
		var decodedResult:Object = result ? JSON.decode(result) : null;
		var uiCallback:Function = openUICalls[method];
		if (uiCallback === null) {
			delete openUICalls[method];
		} else {
			uiCallback(decodedResult);
			delete openUICalls[method];
		}
	}

    /**
     * @private
     *
     */
    protected function handleLogout():void {
	  session = null;
      if (_logoutCallback != null) {
        _logoutCallback(true);
        _logoutCallback = null;
      }
    }

    /**
     * @private
     *
     */
    protected function handleJSEvent(event:String,
                     result:String = null
    ):void {

      if (jsCallbacks[event] != null) {
        var decodedResult:Object;
        try {
          decodedResult = JSON.decode(result);
        } catch (e:JSONParseError) { }

        for (var func:Object in jsCallbacks[event]) {
          (func as Function)(decodedResult);
          delete jsCallbacks[event][func];
        }
      }
    }

    /**
     * @private
     *
     */
    protected function handleSessionChange(result:String,
                         permissions:String = null
    ):void {
      var resultObj:Object;
      var success:Boolean = true;

      if (result != null) {
        try {
          resultObj = JSON.decode(result);
        } catch (e:JSONParseError) {
          success = false;
        }
      } else {
        success = false;
      }

      if (success) {
        if (session == null) {
          session = new GamestamperSession();
          session.fromJSON(resultObj);
        } else {
          session.fromJSON(resultObj);
        }

        if (permissions != null) {
          try {
            session.availablePermissions = JSON.decode(permissions);
          } catch (e:JSONParseError) {
            session.availablePermissions = null;
          }
        }
      }

      if (_initCallback != null) {
        _initCallback(session, null);
        _initCallback = null;
      }

      if (_loginCallback != null) {
        _loginCallback(session, null);
        _loginCallback = null;
      }
    }

    /**
     * @private
     *
     */
    protected static function getInstance():Gamestamper {
      if (_instance == null) {
        _canInit = true;
        _instance = new Gamestamper();
        _canInit = false;
      }
      return _instance;
    }
  }
}
