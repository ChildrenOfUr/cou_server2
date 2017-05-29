import 'package:cou_server2/cou_server2.dart';

class UserController extends HTTPController {
	@httpGet
	Future<Response> getUser(@HTTPPath("id") int id) async {
		Query<User> userQuery = new Query<User>();
		userQuery.where.id = whereEqualTo(id);
		try {
			User user = await userQuery.fetchOne();
			if (user == null) {
				return new Response.notFound();
			}
			return new Response.ok(user);
		} catch (e) {
			return new Response.serverError(body: e.toString());
		}
	}

	@httpGet
	Future<Response> getUserQuery(
		{@HTTPQuery("username") String username, @HTTPQuery(
			"email") String email, @HTTPQuery("offset") int offset}) async {
		Query<User> userQuery = new Query<User>()
			..pageBy((User u) => u.id, QuerySortOrder.ascending)
			..fetchLimit = 10
			..offset = offset ?? 0;
		if (username != null) {
			userQuery.where.username =
				whereContainsString(username, caseSensitive: false);
		}
		if (email != null) {
			userQuery.where.email =
				whereContainsString(email, caseSensitive: false);
		}
		List<User> users = await userQuery.fetch();
		return new Response.ok(users);
	}
}