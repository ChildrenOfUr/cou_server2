import 'dart:async';

import 'package:aqueduct/aqueduct.dart';
import 'package:cou_server2/cou_server2.dart';

main() async {
	try {
		var app = new Application<ServerRequestSink>();
		var config = new ApplicationConfiguration()
			..port = 8081
			..configurationFilePath = "config.yaml";

		app.configuration = config;

		await app.start(numberOfInstances: 3);
	} catch (e, st) {
		await writeError("$e\n $st");
	}
}

Future writeError(String error) async {
	print(error);
}