package oink.nethaxe;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

/**
 * prepares and packages a packet for transmission
 */
class Packet {

	private static var initialised:Bool = false;
	
	private static var buffer:BytesBuffer;
	private static var map:Map<String, Dynamic>;
	
	private static var num_args:Int = 0;
	private static var length:Int;
	
	public static var result:Bytes;
	
	public function new() {
		
	}
	
	public static function init() {
		if(!initialised) {
			map = new Map<String, Dynamic>();
			length = 0;
			num_args = 0;
			initialised = true;
		}
	}
	
	public static function begin(Msg_Type:String = "DEFAULT") {
		init();
		
		buffer = new BytesBuffer();
		buffer.addString("XP/" + Msg_Type + "\n");
		
		num_args = 0;
	}
	
	public static function end():Bytes {
		
		// write number of arguments
		buffer.addDouble(num_args);
		
		for (key in map.keys()) {
			buffer.addString(key + "|");
		}
		
		buffer.addString("\n");
		
		for (key in map.keys()) {
			var arg_type = extract_arg_type(key);
			switch (arg_type) {
				case "BYTE":
					buffer.addByte(map.get(key));
				case "BYTES":
					var bytes = map.get(key);
					buffer.addBytes(bytes, 0, bytes.length);
				case "DOUBLE":
					buffer.addDouble(map.get(key));
				case "FLOAT":
					buffer.addFloat(map.get(key));
				case "STRING":
					buffer.addString(map.get(key));
				default:
					// write it as a string
					buffer.addString(Std.string(map.get(key)));
			}
			buffer.addString("|");
		}
		
		result = buffer.getBytes();
		
		length = 0;
		num_args = 0;
		
		return result;
	}
	
	//public static function read(In:Bytes):Map<String, Dynamic> {
	//
	//}
	
	public static function addByte(Key:String, Value:Int) {
		map.set(Key + ":" + "BYTE", Value);
	}
	//public static function addByte(Value:Int) {
	//	map.set(Std.string(num_args) + ":" + "BYTE", Value);
	//}
	public static function addBytes(Key:String, Value:Bytes) {
		map.set(Key + ":" + "BYTES", Value);
	}
	//public static function addBytes(Value:Bytes) {
	//	map.set(Std.string(num_args) + ":" + "BYTES", Value);
	//}
	public static function addDouble(Key:String, Value:Dynamic) {
		map.set(Key + ":" + "DOUBLE", Value);
	}
	//public static function addDouble(Value:Float) {
	//	map.set(Std.string(num_args) + ":" + "DOUBLE", Value);
	//}
	public static function addFloat(Key:String, Value:Float) {
		map.set(Key + ":" + "FLOAT", Value);
	}
	//public static function addFloat(Value:Float) {
	//	map.set(Std.string(num_args) + ":" + "FLOAT", Value);
	//}
	public static function addString(Key:String, Value:String) {
		map.set(Key + ":" + "STRING", Value);
	}
	//public static function addString(Value:String) {
	//	map.set(Std.string(num_args) + ":" + "STRING", Value);
	//}

	private static function extract_arg_type(Arg:String):String {
		var r = ~/:(.)\w+/g;
		r.match(Arg);
		if (r.matched(1) == null) return "NULL";
		else return r.matched(1).substring(1);
	}
}