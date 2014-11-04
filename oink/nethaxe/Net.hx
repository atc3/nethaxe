package oink.nethaxe;

class Net {
	
	public static var server:Server;
	public static var client:Client;
	
	public static function create_server():Void {
		server = new Server();
	}
	public static function create_client():Void {
		client = new Client();
	}
	
}
