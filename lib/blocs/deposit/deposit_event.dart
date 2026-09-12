part of 'deposit_bloc.dart';

sealed class DepositEvent extends Equatable {
  const DepositEvent();

  @override
  List<Object> get props => [];
}

class FetchDeposits extends DepositEvent {
  final String customerId;

  FetchDeposits(this.customerId);
}

class UploadImageTransferEvent extends DepositEvent {
  final XFile imageFile;
  final String depositId;

  UploadImageTransferEvent({required this.imageFile, required this.depositId});
}
