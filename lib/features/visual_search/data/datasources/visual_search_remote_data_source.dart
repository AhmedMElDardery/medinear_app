abstract class VisualSearchRemoteDataSource {
  Future<Map<String, dynamic>?> searchMedication(String query);
}

class VisualSearchRemoteDataSourceImpl implements VisualSearchRemoteDataSource {
  @override
  Future<Map<String, dynamic>?> searchMedication(String query) async {
    // Mock API Call
    await Future.delayed(const Duration(seconds: 2));

    // Simulate fuzzy match success if query has some length
    if (query.trim().length > 2) {
      return {
        "id": "mock_id_123",
        "name": "Mock Medication for '$query'",
        "description": "This is a mocked result for the visual search.",
      };
    } else {
      throw Exception("No medication found.");
    }
  }
}
