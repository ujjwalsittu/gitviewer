import 'package:gitviewer/github/core/domain/github_repo.dart';
import 'package:gitviewer/github/core/infrastructure/github_repo_dto.dart';

extension DTOListToDomainList on List<GithubRepoDTO> {
  List<GithubRepo> toDomain() {
    return map((e) => e.toDomain()).toList();
  }
}
