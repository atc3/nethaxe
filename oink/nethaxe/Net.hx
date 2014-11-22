package oink.nethaxe;

import pgr.dconsole.DC;

class Net {

	public static inline var DEFAULT_HOSTNAME:String = '127.0.0.1';
	public static inline var DEFAULT_PORT:Int = 3000;
	
	public static var server:Server;
	public static var client:Client;
	
	public static var server_active:Bool = false;
	public static var client_active:Bool = false;
	
	public static function create_server():Void {
		server = new Server();
	}
	public static function create_client():Void {
		client = new Client();
	}
	
	public static function xp_protocol_check(text:String):String {
		// check protocol
		var protocol = text.substr(0, 2);
		if (protocol != "XP") {	return ""; }
		
		var r = ~/[A-Z]+/g;
		var msg_type = text.substr(3);
		
		DC.log("MSG_TYPE: " + msg_type);
		
		return msg_type;
	}
	
	public static function destroy():Void {
		
	}
	
}
