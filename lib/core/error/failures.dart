/// Lightweight Failure hierarchy used by repositories to return typed
/// errors instead of throwing across layer boundaries.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A database error occurred.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ImportFailure extends Failure {
  const ImportFailure(super.message);
}

class FileFailure extends Failure {
  const FileFailure([super.message = 'Unable to read the selected file.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Item not found.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}

/// Simple Result type to avoid throwing exceptions across the
/// repository -> presentation boundary.
class Result<T> {
  final T? data;
  final Failure? failure;
  const Result._({this.data, this.failure});

  factory Result.success(T data) => Result._(data: data);
  factory Result.error(Failure failure) => Result._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isError => failure != null;
}
