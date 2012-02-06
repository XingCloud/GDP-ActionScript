package com.xingcloud.gdp.suport
{
	import flash.display.Stage;
	import flash.events.AsyncErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.Security;
	
	/**
	 * 请开发者直接使用 <code>GDP.instance</code> 来使用行云GDP服务。无需关注本类。 
	 * @author XingCloudly
	 */
	public class RequestManager
	{
		private const DEBUG:Boolean = false ;
		private const API_BRIDGE:String = "clientCallBridge";
		private const SDK_BRIDGE:String = "_sdkBridge";
		private const SDK_CLIENT:String = "_sdkClient";
		private const SDK_CLIENT_VERSION:String = "2.0.3.120206";
		private var _sdkBridgeName:String;
		private var _sdkClientName:String;
		private var _isBridgeReady:Boolean=false;
		private var _connection:LocalConnection;
		private var _activeService:Service;
		private var _stockService:Array = [] ;
		private var _allService:Array = [] ;
		private var _allCallBack:Array = [] ;
		private var _stage:Stage;
		
		/**
		 * 请开发者直接使用 <code>GDP.instance</code> 来使用行云GDP服务。 
		 * @throws Error please access by GDP.instance.callService()
		 * @see #GDP.instance.callService() 
		 */
		public function RequestManager(stage:Stage, connectionKey:String):void
		{   
			_stage = stage ;
			if(_stage && connectionKey == SDK_CLIENT)
			{
				var connectionId:String = _stage.loaderInfo.parameters["connection_id"] ;
				_sdkBridgeName = SDK_BRIDGE + connectionId ;
				_sdkClientName = SDK_CLIENT + connectionId ;
				initConnection() ;
			}
			else
				throw new Error("please access by GDP.instance.callService()") ;
			
			addDebugInfo("version " + SDK_CLIENT_VERSION) ;
		}
		
		/**
		 * 请开发者直接使用 <code>GDP.instance</code> 来使用行云GDP服务。  
		 */
		public function responseFromBridge(serviceId:String, response:Object):void
		{
			var ids:Array = serviceId.split("_") ;
			if(serviceId == "bridgeReady")
			{
				addDebugInfo("get bridge's connection");
				addDebugInfo("are you ready? \n"); // which country and what generation of coders you are? 
				_isBridgeReady=true;
				processStockService() ;
			}
			else if(serviceId == "printStage")
			{
				addDebugInfo("get bridge's print commond") ;
				/*var bd:BitmapData = new BitmapData(_stage.stageWidth, _stage.stageHeight) ;
				bd.draw(_stage) ;
				var ba:ByteArray = bd.getPixels(bd.rect) ;
				ba.compress() ;
				//addDebugInfo("byteArray: " + ba.toString()) ;
				
				var serviceName:String = "window.xcPrintStage_" + Math.round(Math.random()*int.MAX_VALUE) ;
				var tempJSFun:String = "function(arg){" + serviceName + "=arg}" ;
				if(ExternalInterface.available)
				{
					ExternalInterface.call(tempJSFun, ba) ;
					if(_connection)
						_connection.send(_sdkBridgeName, API_BRIDGE, 
								serviceId, serviceName, null);
				}
				else
					addDebugInfo("printStage failed for ExternalInterface is unavailable") ;*/
			}
			else if(ids.length == 2)
			{
				addDebugInfo("get response from bridge of service: " + serviceId + " \n") ;
				_allCallBack[uint(ids[1])](response) ;
			}
			else
			{
				addDebugInfo("for update interface, service wont work: " + serviceId + " \n") ;
			}
		}
		
		/**
		 * 请开发者直接使用 <code>GDP.instance</code> 来使用行云GDP服务。 
		 */
		public function addServiceRequest(serviceName:String, params:Object, callBack:Function):void
		{
			addDebugInfo("call service: " + serviceName) ;
			
			var len:int = _allCallBack.length ;
			for (var i:int = 0; i < len; i++) 
			{
				if(_allCallBack[i] == callBack) break ;
			}
			_allCallBack[i] = callBack ;
			
			var serviceId:String = _allService.length + "_" + i ;
			var service:Service = new Service(serviceId, serviceName, params) ;
			_allService.push(service) ;
			_stockService.push(service) ;
			processStockService() ;
		}
		
		/**
		 * 初始化连接。
		 */
		private function initConnection():void
		{
			Security.allowDomain("*") ;
			Security.allowInsecureDomain("*") ;
			
			_connection=new LocalConnection();
			_connection.client=this; // 此行不能去掉，FK Adobe
			_connection.allowDomain("*");
			_connection.addEventListener(StatusEvent.STATUS, onStatus);
			_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
			_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			try
			{
				_connection.connect(_sdkClientName);
				addDebugInfo("connection inited");
			} 
			//TypeError — connectionName 或 methodName 的值为空。 请将非空值传递给这些参数。  
		 	//ArgumentError原因：1) connectionName 或 methodName 的值为空字符串。2) methodName 中指定的方法受限。 3) 正在发送的序列化消息过大（超过 40K）。
			catch(error:ArgumentError) 
			{
				addDebugInfo("set connection name error: " + error);
			}
		}
		
		/**
		 * 处理服务队列。 
		 */
		private function processStockService():void
		{
			if(_isBridgeReady && _activeService == null && _stockService.length > 0)
			{
				_activeService = _stockService.shift() ;
				performServiceRequest() ;
			}
		}
		
		/**
		 * 处理具体的服务请求。 
		 */
		private function performServiceRequest():void
		{
			addDebugInfo("dealing with service: " + _activeService.serviceName) ;
			try
			{
				_connection.send(_sdkBridgeName, API_BRIDGE, 
					_activeService.serviceId, _activeService.serviceName, _activeService.params);
			}
			catch (error:Error)
			{
				onRequestFailed(" when sending: " + error.toString()) ;
			}
		}
		
		/**
		 * 处理正常的返回，请求可能成功或失败。 
		 */
		private function onStatus(event:StatusEvent):void
		{
			if (event.level == "status")
			{
				_activeService = null ;
				processStockService() ;
			}
			else
				onRequestFailed(event.toString()) ;			
		}
		
		/**
		 * 请求失败时统一处理：日志记录、返回错误信息、重置activeService。
		 * @param reason String 失败原因
		 */
		private function onRequestFailed(reason:String):void
		{
			if(_activeService) // 有可能在没有请求的情况下，connection抛错
			{
				addDebugInfo(_activeService.serviceName + " failed for: " + reason) ;
				var ids:Array = _activeService.serviceId.split("_") ;
				_allCallBack[uint(ids[1])]({code:"153", message:"LocalConnection Error"}) ;
				_activeService = null ;
			}
			else
			{
				addDebugInfo("connection failed for: " + reason) ;
			}
			processStockService() ;
		}
		
		/**
		 * 安全沙箱问题。 
		 */
		private function onSecurityError(event:SecurityErrorEvent):void
		{
			onRequestFailed(event.toString());
		}
		
		/**
		 * 记录AsyncError。
		 */
		private function onAsyncError(event:AsyncErrorEvent):void
		{
			onRequestFailed(event.toString());
		}	
		
		/**
		 * 日志输出。 
		 * @param info 要输出的日志信息文本
		 */
		private function addDebugInfo(info:String):void
		{
			if(DEBUG)
				trace("Client:", info) ;
			// call JSProxy.addDebugInfo(info) ;
		}
		
	}
}

class Service
{
	public var serviceId:String ;
	public var serviceName:String ;
	public var params:Object ;
	
	public function Service(serviceId:String, serviceName:String, params:Object):void
	{
		this.serviceId = serviceId ;
		this.serviceName = serviceName ; // 不会为空，为空到不了这里
		this.params = params ;
	}
}
