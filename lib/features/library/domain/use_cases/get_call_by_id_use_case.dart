import 'package:fpdart/fpdart.dart';
import 'package:hunting_calls_perfection/features/library/data/reference_database.dart';
import 'package:hunting_calls_perfection/features/library/domain/failures/library_failure.dart';
import 'package:hunting_calls_perfection/features/library/domain/reference_call_model.dart';

/// Use case for retrieving a specific reference call by ID
class GetCallByIdUseCase {
  const GetCallByIdUseCase();
  
  /// Execute the use case
  /// 
  /// [callId] - The unique identifier of the call to retrieve
  /// 
  /// Returns the requested call or a failure if not found or library not initialized
  Either<LibraryFailure, ReferenceCall> execute(String callId) {
    try {
      final calls = ReferenceDatabase.calls;
      
      if (calls.isEmpty) {
        return left(const LibraryNotInitialized());
      }
      
      // Try to find the call
      final call = calls.where((c) => c.id == callId).firstOrNull;
      
      if (call == null) {
        return left(CallNotFound(callId));
      }
      
      return right(call);
    } catch (e) {
      return left(JsonLoadError(e.toString()));
    }
  }
}
