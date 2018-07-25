import 'package:cou_server2/cou_server2.dart';

class ApiAccess extends ManagedObject<_ApiAccess> implements _ApiAccess {}

class _ApiAccess {
	static String tableName() => "api_access";

	@primaryKey
	int id;

	@Column()
	String api_token;

	@Column()
	int access_count;

	@Relate(#api_access, isRequired: true, onDelete: DeleteRule.restrict)
	User user;
}
