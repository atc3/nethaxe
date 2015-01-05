package oink.nethaxe;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import pgr.dconsole.DC;

class Net {

	public static inline var DEFAULT_HOSTNAME:String = '127.0.0.1';
	public static inline var DEFAULT_PORT:Int = 3000;
	
	public static var server:Server;
	public static var client:Client;
	
	public static var server_active:Bool = false;
	public static var client_active:Bool = false;
	
	public static function init():Void {
		
	}
	
	public static function create_server():Void {
		server = new Server();
	}
	public static function create_client():Void {
		client = new Client();
	}
	
	/**
	 * helper function to verify arguments of bson packets before processing
	 * @param	Packet BSON packet to check
	 * @param	Fields Array of fields to check
	 * @return Array of fields that exist in Packet
	 */
	public static function verify_fields(Packet:Dynamic, Fields:Array<String>):Array<String> {
		if (Packet == null) return null;
		if (Fields.length <= 0) return null;
		
		var out:Array<String> = [];
		
		for (field in Fields) {
			if (Reflect.hasField(Packet, field)) out.push(field);
		}
		
		return out;
	}
	
	public static function destroy():Void {
		
	}
	
}
