import 'package:fpdart/fpdart.dart';
import 'package:outcall/features/library/data/reference_database.dart';
import 'package:outcall/features/library/domain/failures/library_failure.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

/// Use case for retrieving all reference calls from the library
class GetAllCallsUseCase {
  const GetAllCallsUseCase();
  
  /// Execute the use case
  /// 
  /// Returns all available reference calls or a failure if the library
  /// hasn't been initialized
  Either<LibraryFailure, List<ReferenceCall>> execute() {
    try {
      final calls = ReferenceDatabase.calls;
      
      // Check if library is initialized (empty list could mean not initialized)
      if (calls.isEmpty) {
        return left(const LibraryNotInitialized());
      }
      
      return right(calls);
    } catch (e) {
      return left(JsonLoadError(e.toString()));
    }
  }
}
