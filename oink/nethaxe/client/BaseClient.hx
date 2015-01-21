package oink.nethaxe.client;

import pgr.dconsole.DC;
import org.bsonspec.BSON;
import org.bsonspec.ObjectID;

/**
 * handy class with a few core on functions.
 * showcases extendability of client class
 */
class BaseClient extends Client {

	public function new(Hostname:String='', Port:Int=0) {
		super(Hostname, Port);
		
		// on mapping
		on("INFO", on_info);
		on("PONG", on_pong);
		
		// DC functions
		DC.registerFunction(onChatLine, "chat");
	}
	
	override public function connect(Hostname:String = '', Port:Int = 0) {
		super.connect(Hostname, Port);
		
		// assign us a random name
		id = Std.int(Math.random() * 65536);
		onChatLine('/name User' + id);
	}
	
	function onChatLine(text:String):Bool {
		
		var chat_packet = BSON.encode({
			_id: new ObjectID()
			, action: "CHAT"
			, text: text
		});
		
		try {
			socket.output.write(chat_packet);
		} catch (z:Dynamic) {
			trace('Connection lost.');
			return false;
		}
		return true;
	}
	
	public function ping() {
		
		var ping_packet = BSON.encode({
			_id: new ObjectID()
			, action: "PING"
		});
		
		try {
			trace("pinging server...");
			socket.output.write(ping_packet);
		} catch (z:Dynamic) {
			trace("connection lost.");
		}
	}
	
	public function send_player_location(X:Float, Y:Float) {
		
		var location_packet = BSON.encode({
			_id: new ObjectID()
			, action: "REMOTEPLAYERLOC"
			, client_id: this.id
			, x: X
			, y: Y
		});
		
		try {
			socket.output.write(location_packet);
		} catch (z:Dynamic) {
			trace("connection lost.");
		}
	}
	
	function on_info(packet) {
		if (!Reflect.hasField(packet, "text")) return;
		
		trace("INFO>" + packet.text);
	}
	function on_pong(packet) {
		trace("server ponged");
	}
	
}