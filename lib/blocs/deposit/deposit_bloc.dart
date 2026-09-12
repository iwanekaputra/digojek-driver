import 'package:bloc/bloc.dart';
import 'package:deliq_delivery/models/deposit_model.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

part 'deposit_event.dart';
part 'deposit_state.dart';

class DepositBloc extends Bloc<DepositEvent, DepositState> {
  DepositBloc() : super(DepositInitial()) {
    on<DepositEvent>((event, emit) async {
      // TODO: implement event handler

      if (event is FetchDeposits) {
        emit(DepositLoading());

        try {
          final deposits = await SharedServices().getDeposits(event.customerId);
          print(deposits);
          emit(DepositLoaded(deposits));
        } catch (e) {
          emit(DepositError(e.toString()));
        }
      }

      if (event is UploadImageTransferEvent) {
        emit(DepositUploadImageLoading());

        try {
          // final imageUrl = await SharedServices()
          //     .uploadImageTransfer(event.imageFile, event.depositId);

          // emit(DepositUploadImageSuccess(imageUrl: imageUrl));
        } catch (e) {
          emit(DepositUploadImageFailure(message: e.toString()));
        }
      }
    });
  }
}
