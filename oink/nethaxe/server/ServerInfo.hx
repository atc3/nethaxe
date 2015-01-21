package oink.nethaxe.server ;

import sys.net.Host;

import pgr.dconsole.DC;

import oink.nethaxe.client.ClientInfo;

/**
 * Wrapper for the server socket
 * taken from yellowafterlife's chat demo
 */
class ServerInfo extends ClientInfo {
	/**
	 * hostname server is bound to.
	 */
	public var hostname:String;
	
	/** 
	 * port server is bound to.
	 */
	public var port:Int;
	
	/** 
	 * host object. used by sockets
	 */
	public var host:Host;
	
	/**
	 * constructor
	 * @param	sv server object
	 */
	public function new(sv:Server) {
		super(sv, null);
		name = 'Server';
	}
	
	/**
	 * 
	 * @return
	 */
	override public function toString():String {
		return name + '(console)';
	}
	
	/**
	 * disable client send func
	 * @param	Text
	 * @param	Action
	 */
	override public function send(Text:String, Action:String = "INFO") {
		trace(Text);
	}
}