import 'package:auto_route/auto_route.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gitviewer/auth/application/auth_notifier.dart';
import 'package:gitviewer/auth/shared/providers.dart';
import 'package:gitviewer/core/presentation/routes/app_router.gr.dart';
import 'package:gitviewer/core/shared/providers.dart';

final initializationProvider = FutureProvider<Unit>((ref) async {
  await ref.read(sembastProvider).init();
  ref.read(dioProvider)
    ..options = BaseOptions(
      headers: {
        'Accept': 'application/vnd.github.v3.html+json',
      },
      validateStatus: (status) =>
          status != null && status >= 200 && status < 400,
    )
    ..interceptors.add(ref.read(oAuth2InterceptorProvider));
  final authNotifier = ref.read(authNotifierProvider.notifier);
  await authNotifier.checkAndUpdateAuthStatus();
  return unit;
});

class AppWidget extends ConsumerWidget {
  final appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetReference ref) {
    // ref.listen<AuthState>(authNotifier, (state) {

    // });
    return ProviderListener(
      provider: initializationProvider,
      onChange: (context, value) {},
      // child: ProviderListener<AuthState>(
        provider: authNotifierProvider,
        onChange: (context, state) {
          state.maybeMap(
              orElse: () {},
              authenticated: (_) {
                appRouter.pushAndPopUntil(
                  const StarredReposRoute(),
                  predicate: (route) => false,
                );
              },
              unauthenticated: (_) {
                appRouter.pushAndPopUntil(
                  const SignInRoute(),
                  predicate: (route) => false,
                );
              });
        },
        child: MaterialApp.router(
          title: 'Repo Viewer',
          theme: _setUpThemeData(),
          routerDelegate: appRouter.delegate(),
          routeInformationParser: appRouter.defaultRouteParser(),
        ),
      ),
    );
  }

  ThemeData _setUpThemeData() {
    return ThemeData(
      primaryColor: Colors.grey.shade50,
    );
  }
}
