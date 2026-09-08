// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importRepository)
final importRepositoryProvider = ImportRepositoryProvider._();

final class ImportRepositoryProvider
    extends
        $FunctionalProvider<
          ImportRepository,
          ImportRepository,
          ImportRepository
        >
    with $Provider<ImportRepository> {
  ImportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportRepository create(Ref ref) {
    return importRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportRepository>(value),
    );
  }
}

String _$importRepositoryHash() => r'e7b2322b8f4891a0638ed0c4e7622a3c963aba4d';

/// One import job, re-read until the server is done with it.
///
/// D12 rules out Realtime, and D14 says the client polls, so this is a loop.
/// It is the first one in the app: the only other `async*` providers wrap
/// `onAuthStateChange`, which pushes.
///
/// Not `keepAlive`. An abandoned import should not outlive its screen, and
/// the cancellation below depends on being disposed.

@ProviderFor(importJob)
final importJobProvider = ImportJobFamily._();

/// One import job, re-read until the server is done with it.
///
/// D12 rules out Realtime, and D14 says the client polls, so this is a loop.
/// It is the first one in the app: the only other `async*` providers wrap
/// `onAuthStateChange`, which pushes.
///
/// Not `keepAlive`. An abandoned import should not outlive its screen, and
/// the cancellation below depends on being disposed.

final class ImportJobProvider
    extends
        $FunctionalProvider<AsyncValue<ImportJob>, ImportJob, Stream<ImportJob>>
    with $FutureModifier<ImportJob>, $StreamProvider<ImportJob> {
  /// One import job, re-read until the server is done with it.
  ///
  /// D12 rules out Realtime, and D14 says the client polls, so this is a loop.
  /// It is the first one in the app: the only other `async*` providers wrap
  /// `onAuthStateChange`, which pushes.
  ///
  /// Not `keepAlive`. An abandoned import should not outlive its screen, and
  /// the cancellation below depends on being disposed.
  ImportJobProvider._({
    required ImportJobFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'importJobProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$importJobHash();

  @override
  String toString() {
    return r'importJobProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ImportJob> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ImportJob> create(Ref ref) {
    final argument = this.argument as String;
    return importJob(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImportJobProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$importJobHash() => r'4e1a6da364398a900a6d084975c16dc9e48574bb';

/// One import job, re-read until the server is done with it.
///
/// D12 rules out Realtime, and D14 says the client polls, so this is a loop.
/// It is the first one in the app: the only other `async*` providers wrap
/// `onAuthStateChange`, which pushes.
///
/// Not `keepAlive`. An abandoned import should not outlive its screen, and
/// the cancellation below depends on being disposed.

final class ImportJobFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ImportJob>, String> {
  ImportJobFamily._()
    : super(
        retry: null,
        name: r'importJobProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One import job, re-read until the server is done with it.
  ///
  /// D12 rules out Realtime, and D14 says the client polls, so this is a loop.
  /// It is the first one in the app: the only other `async*` providers wrap
  /// `onAuthStateChange`, which pushes.
  ///
  /// Not `keepAlive`. An abandoned import should not outlive its screen, and
  /// the cancellation below depends on being disposed.

  ImportJobProvider call(String jobId) =>
      ImportJobProvider._(argument: jobId, from: this);

  @override
  String toString() => r'importJobProvider';
}
