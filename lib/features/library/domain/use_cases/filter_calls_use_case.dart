import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/failures/library_failure.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

/// Use case for filtering reference calls by category and search query
class FilterCallsUseCase {
  const FilterCallsUseCase();
  
  /// Execute the use case
  /// 
  /// [category] - Category to filter by (e.g., "All", "Waterfowl", "Big Game")
  /// [searchQuery] - Search query to match against animal name or call type (case-insensitive)
  /// 
  /// Returns filtered and sorted list of calls or a failure if library not initialized
  Either<LibraryFailure, List<ReferenceCall>> execute({
    required String category,
    required String searchQuery,
  }) {
    try {
      final calls = ReferenceDatabase.calls;
      
      if (calls.isEmpty) {
        return left(const LibraryNotInitialized());
      }
      
      // Filter calls based on search query and category
      final filtered = calls.where((call) {
        final matchesSearch = searchQuery.isEmpty ||
            call.animalName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            call.callType.toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesCategory = category == 'All' || call.category == category;
        
        return matchesSearch && matchesCategory;
      }).toList();
      
      // Sort alphabetically by animal name
      filtered.sort((a, b) => a.animalName.compareTo(b.animalName));
      
      return right(filtered);
    } catch (e) {
      return left(JsonLoadError(e.toString()));
    }
  }
}
