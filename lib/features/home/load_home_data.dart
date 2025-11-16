//lib/features/home/load_home_data.dart
import 'home_repository.dart';

/// Encapsulates how Home data is loaded (offline + online)
class LoadHomeData {
  final HomeRepository repository;
  LoadHomeData(this.repository);

  Future<Map<String, dynamic>> execute() async {
    final offline = repository.getLocalActivity();
    return {'offline': offline};
  }
}
