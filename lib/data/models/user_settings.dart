import 'package:hive/hive.dart';
part 'user_settings.g.dart';

@HiveType(typeId: 3)
class UserSettings {
  @HiveField(0)
  final bool isDarkMode;

  @HiveField(1)
  final String preferredCategory;

  @HiveField(2)
  final double soundVolume;

  UserSettings({
    required this.isDarkMode,
    required this.preferredCategory,
    required this.soundVolume,
  });
}
