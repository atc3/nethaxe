package oink.nethaxe;

import pgr.dconsole.DC;
import sys.net.Host;

/**
 * Wrapper for the server socket
 */
class ServerInfo extends ClientInfo {
	
	// defaults
	public static inline var DEFAULT_HOSTNAME:String = '127.0.0.1';
	public static inline var DEFAULT_PORT:Int = 3000;
	
	// hostname server is bound to.
	public var hostname:String;
	// port server is bound to.
	public var port:Int;
	
	// host object. used by sockets
	public var host:Host;
	
	public function new(sv:Server) {
		super(sv, null);
		name = 'Server';
	}
	override public function toString():String {
		return name + '(console)';
	}
	override public function send(text:String) {
		DC.log(text);
	}
}