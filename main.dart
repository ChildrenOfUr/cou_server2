import 'package:cou_server2/cou_server2.dart';

Future main() async {
	try {
		app = Application<GameServer>()
			..options.configurationFilePath = "config.yaml"
			..options.port = 8181;

		await app.start(numberOfInstances: 3);
		print("Application running on port ${app.options.port}");
	} catch (e, st) {
		print("$e\n $st");
	}
}
