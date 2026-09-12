class Result<T> {
  final T? value;
  final String? error;
  final Map<String, dynamic>? validationErrors;

  bool get isSuccess => error == null && validationErrors == null;
  bool get isError => error != null && validationErrors == null;
  bool get isValidationError => validationErrors != null;

  Result._({this.value, this.error, this.validationErrors});

  factory Result.success(T value) => Result._(value: value);
  factory Result.error(String error) => Result._(error: error);
  factory Result.validationErrors(Map<String, dynamic> validationErrors) =>
      Result._(validationErrors: validationErrors);
}
