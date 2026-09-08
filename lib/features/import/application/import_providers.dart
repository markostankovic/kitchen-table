import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/import_repository.dart';
import '../domain/import_job.dart';

part 'import_providers.g.dart';

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) =>
    ImportRepository(ref.watch(supabaseClientProvider));

/// How often to ask whether the server has finished.
///
/// import-text takes a few seconds; a cookbook photo will take thirty (D14).
/// 1.5 s is short enough that a fast text import feels immediate and long
/// enough that a slow one is not a hundred wasted requests.
const Duration _pollInterval = Duration(milliseconds: 1500);

/// When to stop asking.
///
/// Not a failure state -- the last status stays on screen and the user can
/// retry. It exists so that a worker that died mid-job leaves a spinner that
/// eventually stops rather than one that spins until the app is killed.
const Duration _pollCeiling = Duration(minutes: 3);

/// One import job, re-read until the server is done with it.
///
/// D12 rules out Realtime, and D14 says the client polls, so this is a loop.
/// It is the first one in the app: the only other `async*` providers wrap
/// `onAuthStateChange`, which pushes.
///
/// Not `keepAlive`. An abandoned import should not outlive its screen, and
/// the cancellation below depends on being disposed.
@riverpod
Stream<ImportJob> importJob(Ref ref, String jobId) async* {
  final ImportRepository repository = ref.watch(importRepositoryProvider);

  // A generator is not stopped mid-`await`; it stops at the next yield. So a
  // popped screen would otherwise keep polling for up to one interval past its
  // own disposal, and on a failing request, forever. Nothing in this codebase
  // had established a cancellation idiom for a delay, so here is one.
  bool disposed = false;
  ref.onDispose(() => disposed = true);

  final DateTime deadline = DateTime.now().add(_pollCeiling);

  ImportJob job = await repository.fetch(jobId);
  yield job;

  while (job.status.isPending && !disposed) {
    if (DateTime.now().isAfter(deadline)) return;
    await Future<void>.delayed(_pollInterval);
    if (disposed) return;

    job = await repository.fetch(jobId);
    yield job;
  }
}
