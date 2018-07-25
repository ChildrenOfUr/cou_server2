import 'package:cou_server2/cou_server2.dart';

enum UserIdentifierType {
	ID,
	USERNAME,
	EMAIL
}

class UserController extends ResourceController {
	@Operation.get("id")
	Future<Response> getUserById() async {
		final int id = int.parse(request.path.variables["id"]);
		return _getUser(id, UserIdentifierType.ID);
	}

	@Operation.get("username")
	Future<Response> getUserByUsername() async {
		final String username = request.path.variables["username"];
		return _getUser(username, UserIdentifierType.USERNAME);
	}

	@Operation.get("email")
	Future<Response> getUserByEmail() async {
		final String email = request.path.variables["email"];
		return _getUser(email, UserIdentifierType.EMAIL);
	}

	Future<Response> _getUser(dynamic identifier, UserIdentifierType identifierType) async {
		Query<User> userQuery = Query<User>(app.channel.context);

		if (identifierType == UserIdentifierType.ID) {
			userQuery..where((User user) => user.id).equalTo(identifier as int);
		} else if (identifierType == UserIdentifierType.USERNAME) {
			userQuery..where((User user) => user.username).equalTo(identifier as String, caseSensitive: false);
		} else if (identifierType == UserIdentifierType.EMAIL) {
			userQuery..where((User user) => user.email).equalTo(identifier as String, caseSensitive: false);
		} else {
			throw ArgumentError("Invalid UserIdentifierType '$identifierType'");
		}

		try {
			User user = await userQuery.fetchOne();

			if (user == null) {
				return Response.notFound();
			}

			return Response.ok(user);
		} catch (e) {
			return Response.serverError(body: e.toString());
		}
	}
}
