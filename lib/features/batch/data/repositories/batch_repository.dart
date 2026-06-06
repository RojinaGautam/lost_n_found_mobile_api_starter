import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lost_n_found/core/error/failures.dart';
import 'package:lost_n_found/core/services/connectivity/network_info.dart';
import 'package:lost_n_found/features/batch/data/datasources/batch_datasource.dart';
import 'package:lost_n_found/features/batch/data/datasources/local/batch_local_datasource.dart';
import 'package:lost_n_found/features/batch/data/datasources/remote/batch_remote_datasource.dart';
import 'package:lost_n_found/features/batch/data/models/batch_api_model.dart';
import 'package:lost_n_found/features/batch/data/models/batch_hive_model.dart';
import 'package:lost_n_found/features/batch/domain/entities/batch_entity.dart';
import 'package:lost_n_found/features/batch/domain/repositories/batch_repository.dart';

final batchRepositoryProvider = Provider<IBatchRepository>((ref) {
  final localDatasource = ref.read(batchLocalDatasourceProvider);
  final remoteDatasource = ref.read(batchRemoteDataSourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return BatchRepository(
    localDatasource: localDatasource,
    remoteDataSource: remoteDatasource,
    networkInfo: networkInfo,
  );
});

class BatchRepository implements IBatchRepository {
  final IBatchLocalDataSource _localDatasource;
  final IBatchRemoteDataSource _remoteDatasource;
  final NetworkInfo _networkInfo;

  BatchRepository({
    required IBatchLocalDataSource localDatasource,
    required IBatchRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, bool>> createBatch(BatchEntity batch) async {
    try {
      final model = BatchHiveModel.fromEntity(batch);

      final result = await _localDatasource.createBatch(model);

      if (result) {
        return const Right(true);
      }

      return const Left(
        LocalDatabaseFailure(
          message: 'Failed to create batch',
        ),
      );
    } catch (e) {
      return Left(
        LocalDatabaseFailure(
          message: e.toString(),
        ),
      );
    }
  }

@override
  Future<Either<Failure, List<BatchEntity>>> getAllBatches() async {
    if (await _networkInfo.isConnected) {
      try {
        // Fetch from remote API
        final apiModels = await _remoteDatasource.getAllBatches();

        // Convert API models to entities
        final entities = BatchApiModel.toEntityList(apiModels);

        return Right(entities);
      } catch (e) {
        // Fallback to local if remote fails
        try {
          final hiveModels = await _localDatasource.getAllBatches();
          final entities = BatchHiveModel.toEntityList(hiveModels);
          return Right(entities);
        } catch (localError) {
          return Left(
            ApiFailure(
              statusCode: null,
              message: 'Failed to fetch batches from API and local fallback failed',
            ),
          );
        }
      }
    } else {
      try {
        // Fetch from local Hive database
        final hiveModels = await _localDatasource.getAllBatches();

        // Convert Hive models to entities
        final entities = BatchHiveModel.toEntityList(hiveModels);

        return Right(entities);
      } catch (e) {
        return Left(
          LocalDatabaseFailure(
            message: e.toString(),
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, BatchEntity>> getBatchById(
    String batchId,
  ) async {
    try {
      final model = await _localDatasource.getBatchById(batchId);

      if (model == null) {
        return const Left(
          LocalDatabaseFailure(
            message: 'Batch not found',
          ),
        );
      }

      return Right(model.toEntity());
    } catch (e) {
      return Left(
        LocalDatabaseFailure(
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> updateBatch(
    BatchEntity batch,
  ) async {
    try {
      final model = BatchHiveModel.fromEntity(batch);

      final result = await _localDatasource.updateBatch(model);

      if (result) {
        return const Right(true);
      }

      return const Left(
        LocalDatabaseFailure(
          message: 'Failed to update batch',
        ),
      );
    } catch (e) {
      return Left(
        LocalDatabaseFailure(
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteBatch(
    String batchId,
  ) async {
    try {
      final result = await _localDatasource.deleteBatch(batchId);

      if (result) {
        return const Right(true);
      }

      return const Left(
        LocalDatabaseFailure(
          message: 'Failed to delete batch',
        ),
      );
    } catch (e) {
      return Left(
        LocalDatabaseFailure(
          message: e.toString(),
        ),
      );
    }
  }
}