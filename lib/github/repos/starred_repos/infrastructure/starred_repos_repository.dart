import 'package:dartz/dartz.dart';
import 'package:gitviewer/core/domain/fresh.dart';
import 'package:gitviewer/core/infrastructure/network_exceptions.dart';
import 'package:gitviewer/github/core/domain/github_failure.dart';
import 'package:gitviewer/github/core/domain/github_repo.dart';
import 'package:gitviewer/github/repos/starred_repos/infrastructure/starred_repos_local_service.dart';
import 'package:gitviewer/github/repos/starred_repos/infrastructure/starred_repos_remote_service.dart';
import 'package:gitviewer/github/repos/core/infrastructure/extensions.dart';

class StarredReposRepository {
  final StarredReposRemoteService _remoteService;
  final StarredReposLocalService _localService;

  StarredReposRepository(this._remoteService, this._localService);

  Future<Either<GithubFailure, Fresh<List<GithubRepo>>>> getStarredReposPage(
    int page,
  ) async {
    try {
      final remotePageItems = await _remoteService.getStarredReposPage(page);
      return right(
        await remotePageItems.when(
          noConnection: () async => Fresh.no(
            await _localService.getPage(page).then((_) => _.toDomain()),
            isNextPageAvailable: page < await _localService.getLocalPageCount(),
          ),
          notModified: (maxPage) async => Fresh.yes(
            await _localService.getPage(page).then((_) => _.toDomain()),
            isNextPageAvailable: page < maxPage,
          ),
          withNewData: (data, maxPage) async {
            await _localService.upsertPage(data, page);
            return Fresh.yes(
              data.toDomain(),
              isNextPageAvailable: page < maxPage,
            );
          },
        ),
      );
    } on RestApiException catch (e) {
      return left(GithubFailure.api(e.errorCode));
    }
  }
}
