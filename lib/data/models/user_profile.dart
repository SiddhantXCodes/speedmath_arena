import 'package:hive/hive.dart';
part 'user_profile.g.dart';

@HiveType(typeId: 10)
class UserProfile {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int level;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.level,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      level: map['level'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'level': level,
  };
}
