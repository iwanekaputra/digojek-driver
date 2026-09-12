part of 'deposit_bloc.dart';

sealed class DepositState extends Equatable {
  const DepositState();

  @override
  List<Object> get props => [];
}

final class DepositInitial extends DepositState {}

class DepositLoading extends DepositState {}

class DepositLoaded extends DepositState {
  final List<DepositModel> deposits;

  DepositLoaded(this.deposits);
}

class DepositError extends DepositState {
  final String message;

  DepositError(this.message);
}

class DepositUploadImageLoading extends DepositState {}

class DepositUploadImageSuccess extends DepositState {
  final String imageUrl;

  DepositUploadImageSuccess({required this.imageUrl});
}

class DepositUploadImageFailure extends DepositState {
  final String message;

  DepositUploadImageFailure({required this.message});
}
