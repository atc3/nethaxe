package oink.nethaxe.client ;

import haxe.io.Bytes;
import sys.net.Socket;

import org.bsonspec.BSON;
import org.bsonspec.ObjectID;

import oink.nethaxe.server.Server;

/**
 * Wrapper for the client socket.
 * taken from yellowafterlife's chat demo
 */
class ClientInfo {
	
	/**
	 * client socket
	 */
	public var socket:Socket;
	
	/**
	 * name of the client.
	 * unique identifier and tracked by server
	 * TODO: deprecate this and turn unique id into int
	 */
	public var name:String;
	
	/**
	 * server client is connected to
	 */
	public var server:Server;
	
	/**
	 * whether the client is connected/active or not
	 */
	public var active:Bool;
	
	/**
	 * constructor
	 * @param	sv server connected to
	 * @param	skt socket used
	 */
	public function new(sv:Server, skt:Socket) {
		server = sv;
		socket = skt;
		name = '';
		active = true;
	}
	
	/**
	 * 
	 * @return
	 */
	public function toString():String {
		var peer = socket.peer();
		var pstr = Std.string(peer.host) + ':' + peer.port;
		return (name == null || name == '') ? pstr : (name + '(' + pstr + ')');
	}
	
	/**
	 * send text to server
	 * @param	Text
	 * @param	Action
	 */
	public function send(Text:String, Action:String = "INFO") {
		
		var send_packet = BSON.encode({
			_id: new ObjectID()
			, action: Action
			, text: Text
		});
		
		try {
			socket.output.write(send_packet);
		} catch (z:Dynamic) {
			active = false;
		}
	}
}