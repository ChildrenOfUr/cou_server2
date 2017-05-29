import 'package:cou_server2/cou_server2.dart';

class ApiAccess extends ManagedObject<_ApiAccess> implements _ApiAccess {}

class _ApiAccess {
	@ManagedColumnAttributes(primaryKey: true, autoincrement: true)
	int id;

	String api_token;
	int access_count;

	@ManagedRelationship(#api_access, isRequired: true,
		onDelete: ManagedRelationshipDeleteRule.restrict)
	User user;

	static String tableName() => "api_access";
}
