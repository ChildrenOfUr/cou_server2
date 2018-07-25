import 'package:cou_server2/cou_server2.dart';

class APIAuthorizer extends Authorizer {
	APIAuthorizer(AuthValidator validator) : super(validator);

	Future<RequestOrResponse> processRequest(Request request) async {
		String apiKey = request.raw.headers.value("api-key");

		Query<ApiAccess> apiQuery = Query<ApiAccess>(app.channel.context)
			..where((ApiAccess access) => access.api_token).equalTo(apiKey);

		try {
			ApiAccess apiAccess = await apiQuery.fetchOne();

			if (apiAccess.access_count < 100) {
				apiQuery.values.access_count = apiAccess.access_count + 1;
				await apiQuery.updateOne();
				return request;
			} else {
				// there's a cron job to reset it every 15 minutes (*/15 * * * *)
				// so we'll figure out how many seconds until they can try again
				DateTime now = DateTime.now();
				int retry = 0;
				int currentMinute = now.minute;

				if (currentMinute > 44) {
					retry = (60 - currentMinute) * 60;
				} else if (currentMinute > 29) {
					retry = (45 - currentMinute) * 60;
				} else if (currentMinute > 14) {
					retry = (30 - currentMinute) * 60;
				} else {
					retry = (15 - currentMinute) * 60;
				}

				retry -= now.second;
				return Response(429, {"retry-after": retry.toString()}, "Rate limit exceeded");
			}
		} catch (_) {
			return Response.unauthorized();
		}
	}
}