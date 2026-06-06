// Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lost_n_found/core/api/api_client.dart';
import 'package:lost_n_found/core/api/api_endpoints.dart';
import 'package:lost_n_found/features/batch/data/datasources/batch_datasource.dart';
import 'package:lost_n_found/features/batch/data/models/batch_api_model.dart';

final batchRemoteDataSourceProvider = Provider<IBatchRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return BatchRemoteDataSource(apiClient: apiClient);
}); // Provider

class BatchRemoteDataSource implements IBatchRemoteDataSource {
  final ApiClient _apiClient;

  BatchRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<BatchApiModel>> getAllBatches() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.batches);
      final data = response.data['data'] as List? ?? [];
      return data.map((json) => BatchApiModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BatchApiModel> getBatchById(String batchId) async {
    final response = await _apiClient.get(ApiEndpoints.batchById(batchId));
    return BatchApiModel.fromJson(response.data['data']);
  }

  @override
  Future<bool> createBatch(BatchApiModel batch) async {
    final response = await _apiClient.post(
      ApiEndpoints.batches,
      data: batch.toJson(),
    );

    return response.data['success'] == true;
  }
  
  @override
  Future<bool> updateBatch(BatchApiModel batch) {
    // TODO: implement updateBatch
    throw UnimplementedError();
  }
  
  @override
  Future<bool> deleteBatch(String batchId) {
    // TODO: implement deleteBatch
    throw UnimplementedError();
  }
}