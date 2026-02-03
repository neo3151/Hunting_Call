import '../domain/profile_model.dart';
import '../data/local_profile_data_source.dart'; // import the interface definition if simpler
import '../../rating/domain/rating_model.dart';


abstract class ProfileRepository {
  Future<UserProfile> getProfile([String? userId]);
  Future<List<UserProfile>> getAllProfiles();
  Future<UserProfile> createProfile(String name);
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId);

}

class LocalProfileRepository implements ProfileRepository {
  final ProfileDataSource dataSource;

  LocalProfileRepository({required this.dataSource});
  @override
  Future<UserProfile> getProfile([String? userId]) async {
    // If no ID provided, try to fetch the first one or guest?
    // BUT we should really always use the current user from auth.
    // For this method, let's say it returns a specific profile or defaults to guest if unknown.
    final targetId = userId ?? 'guest';
    return dataSource.getProfile(targetId);
  }

  @override
  Future<List<UserProfile>> getAllProfiles() async {
    final ids = await dataSource.getProfileIds();
    final profiles = <UserProfile>[];
    for (var id in ids) {
      profiles.add(await dataSource.getProfile(id));
    }
    return profiles;
  }

  @override
  Future<UserProfile> createProfile(String name) async {
    // Generate simple ID
    final id = "${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}";
    
    final newProfile = UserProfile(
      id: id,
      name: name,
      joinedDate: DateTime.now(),
    );
    
    await dataSource.saveProfile(newProfile);
    await dataSource.addProfileId(id);
    return newProfile;
  }



  @override
  Future<void> saveResultForUser(String userId, RatingResult result, String animalId) async {
    final newItem = HistoryItem(
      result: result,
      timestamp: DateTime.now(),
      animalId: animalId,
    );
    await dataSource.addHistoryItem(userId, newItem);
  }
}
