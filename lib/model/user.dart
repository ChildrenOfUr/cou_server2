import 'package:cou_server2/cou_server2.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
	static String tableName() => "users";

	ManagedSet<Auction> auctions;

	ApiAccess api_access;

	@primaryKey
	int id;

	@Column(unique: true, nullable: false)
	@Validate.length(lessThanEqualTo: 60)
	String email;

	@Column(unique: true, nullable: false)
	@Validate.length(lessThanEqualTo: 30)
	String username;

	@Column(nullable: true)
	String bio;

	@Column(defaultValue: "now()", nullable: false)
	DateTime registration_date;

	@Column(defaultValue: "'#      '")
	@Validate.length(equalTo: 7)
	String username_color;

	@Column(defaultValue: "false", nullable: false)
	bool chat_disabled;

	@Column(defaultValue: "'[]'", nullable: false)
	String achievements;

	@Column(nullable: true)
	DateTime last_login;

	@Column(defaultValue: "'_'", nullable: false)
	@Validate.length(lessThanEqualTo: 10)
	String elevation;

	@Column(nullable: true)
	@Validate.length(lessThanEqualTo: 30)
	String custom_avatar;

	@Column(defaultValue: "'[]'", nullable: false)
	String friends;
}
