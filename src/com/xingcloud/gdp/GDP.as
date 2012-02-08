package com.xingcloud.gdp
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	/**
	 * GDP是Global Distribution Platform的缩写，GDP类是行云GDP核心接口，通过静态实例的 <code>callService</code> 方法来获取平台服务。如获取好友信息：</br>
	 * <code>GDP.instance.callService("get_friends", {type:"all"}, onGetFriends);</code>
	 * @see #callService()
	 * @author XingCloudly
	 */
	public class GDP
	{
		private static var _instance:GDP = new GDP() ; //for appLoaded notice
		private var _service:* ;
		private var _stockService:Array = [] ;
		private var _main:Sprite;
		/**
		 * GDP实例，可以通过该静态实例，获取平台服务。
		 * @see #callService()
		 */
		public static function get instance():GDP
		{
			return _instance;
		}
		
		/**
		 * 单例模式，无需显式调用。
		 * 直接通过 <code>GDP.instance.callService(serviceName, params, callBack)</code> 来获取GDP服务。
		 * @throws Error please access by GDP.instance!
		 * @see #callService()
		 */
		public function GDP():void
		{
			if (_instance)
			{
				throw new Error("GDP: Please access by GDP.instance!");
			}
		}
		
		/**
		 * GDP初始化。
		 * @param main - Sprite or MovieClip 当前应用的主类
		 * @throws Error GDP: param "main" is null or has nonstage!
		 */
		public function init(main:Sprite):void
		{
			if(_main) return ; // 多次调用，聪耳不闻
			if(main == null || main.stage == null)
				throw new Error("GDP: param main is null or has nonstage!") ;
			
			_main = main ;
			
			try
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onServiceLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onServiceLoadError);
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onServiceLoadError);
				var context:LoaderContext = new LoaderContext(false);
				context.applicationDomain = ApplicationDomain.currentDomain;
				var sComponentUrl:String = "GDPService.swf";
				loader.load(new URLRequest(sComponentUrl), context);
			} 
			catch(error:Error) 
			{
				trace("GDP: load GDPService Error: " + error) ;
			}
		}
		
		private function onServiceLoadError(error:ErrorEvent):void
		{
			trace("GDP: load GDPService Error: " + error) ;
		}
		
		private function onServiceLoaded(event:Event):void
		{
			trace("GDP: load GDPService complete.") ;
			
			_service = event.target.content ;
			_service.init(_main) ;
			
			if(_stockService.length > 0)
			{
				for each (var service:Object in _stockService) 
				{
					callService(service.serviceName, service.params, service.callBack) ;
				}
			}
		}
		
		
		/**
		 * 通过<code> GDP.instance.callService() </code>获取平台提供的各种服务，示例如：
		 * <ul>
		 * <li>用户信息 <code>callService("get_user", null, onGetUser);</code></li>
		 * <li>游戏好友 <code>callService("get_friends", {type:"all"}, onGetFriends);</code></li>
		 * <li>发送请求 <code>callService("post_apprequest", {title:"t", body:"b"}, onPostApprequest);</code></li>
		 * <li>发送消息 <code>callService("post_message", {title:"t", body:"b"}, onPostMessage);</code></li>
		 * <li>发新鲜事 <code>callService("post_feed", {title:"t", body:"b"}, onPostFeed);</code></li>
		 * <li>显示支付 <code>callService("show_pay", null, onShowPay);</code></li>
		 * <li>显示邀请 <code>callService("show_invite", null, onShowInvite);</code></li>
		 * <li>重载页面 <code>callService("reload");</code></li>
		 * <li>详情及更新 http://doc.xingcloud.com/pages/viewpage.action?pageId=4195455</li>
		 * </ul>
		 * 下面参数介绍以获取用户好友信息为例。
		 * @param serviceName - String 服务名称，如 <code>"get_friends"</code> 
		 * @param params - Object 服务所相关的参数，如 <code>{type="app"}</code>
		 * @param callBack - Function 服务返回的处理方法，如 <code>function onGetFriends(response:Object):void{ }</code>
		 * @throws Error serviceName can not be null or ""
		 * @throws Error Please initialize GDP by GDP.instance.init(this)
		 * @see http://doc.xingcloud.com/pages/viewpage.action?pageId=4195455 行云GDP在线文档
		 */
		public function callService(serviceName:String, params:Object = null, callBack:Function = null):void 
		{
			if (serviceName == null || serviceName.length < 1)
				throw new Error("GDP: serviceName can not be null or \"\"") ;
			
			if (_main == null)
				throw new Error("GDP: Please initialize GDP by GDP.instance.init(this)");
			
			if (params == null) params = {} ;
			if (callBack == null) callBack = new Function() ;
			
			if(_service)
				_service.callService(serviceName, params, callBack) ;
			else
				_stockService.push({serviceName:serviceName, params:params, callBack:callBack}) ;
		}
	}
}
