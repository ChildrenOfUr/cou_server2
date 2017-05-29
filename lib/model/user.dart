import 'package:cou_server2/cou_server2.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
	@ManagedColumnAttributes(primaryKey: true, autoincrement: true)
	int id;

	@ManagedColumnAttributes(unique: true, nullable: false)
	@Validate.length(lessThanEqualTo: 60)
	String email;

	@ManagedColumnAttributes(unique: true, nullable: false)
	@Validate.length(lessThanEqualTo: 30)
	String username;

	@ManagedColumnAttributes(nullable: true)
	String bio;

	@ManagedColumnAttributes(defaultValue: 'now()', nullable: false)
	DateTime registration_date;

	@ManagedColumnAttributes(defaultValue: '\'#      \'')
	@Validate.length(lessThanEqualTo: 7)
	String username_color;

	@ManagedColumnAttributes(defaultValue: 'false', nullable: false)
	bool chat_disabled;

	@ManagedColumnAttributes(defaultValue: '\'[]\'', nullable: false)
	String achievements;

	@ManagedColumnAttributes(nullable: true)
	DateTime last_login;

	@ManagedColumnAttributes(defaultValue: '\'_\'', nullable: false)
	@Validate.length(lessThanEqualTo: 10)
	String elevation;

	@ManagedColumnAttributes(nullable: true)
	@Validate.length(lessThanEqualTo: 30)
	String custom_avatar;

	@ManagedColumnAttributes(defaultValue: '\'[]\'', nullable: false)
	String friends;

	ManagedSet<Auction> auctions;
	ApiAccess api_access;

	static String tableName() => "users";
}