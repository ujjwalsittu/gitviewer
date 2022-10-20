import 'package:dartz/dartz.dart';
import 'package:gitviewer/core/domain/fresh.dart';
import 'package:gitviewer/core/infrastructure/network_exceptions.dart';
import 'package:gitviewer/github/core/domain/github_failure.dart';
import 'package:gitviewer/github/core/domain/github_repo.dart';
import 'package:gitviewer/github/repos/searched_repos/infrastructure/searched_repos_remote_service.dart';
import 'package:gitviewer/github/repos/core/infrastructure/extensions.dart';

class SearchedReposRepository {
  final SearchedReposRemoteService _remoteService;

  SearchedReposRepository(this._remoteService);

  Future<Either<GithubFailure, Fresh<List<GithubRepo>>>> getSearchedReposPage(
    String query,
    int page,
  ) async {
    try {
      final remotePageItems =
          await _remoteService.getSearchedReposPage(query, page);
      return right(
        remotePageItems.maybeWhen(
          withNewData: (data, maxPage) => Fresh.yes(
            data.toDomain(),
            isNextPageAvailable: page < maxPage,
          ),
          orElse: () => Fresh.no([], isNextPageAvailable: false),
        ),
      );
    } on RestApiException catch (e) {
      return left(GithubFailure.api(e.errorCode));
    }
  }
}
