package oink.nethaxe;

class Net {

	public static inline var DEFAULT_HOSTNAME:String = '127.0.0.1';
	public static inline var DEFAULT_PORT:Int = 3000;
	
	public static var server:Server;
	public static var client:Client;
	
	public static function create_server():Void {
		server = new Server();
	}
	public static function create_client():Void {
		client = new Client();
	}
	
}
