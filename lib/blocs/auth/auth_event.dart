part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthRegister extends AuthEvent {
  final SignUpFormModel data;
  const AuthRegister(this.data);

  @override
  List<Object> get props => [data];
}

class AuthLogin extends AuthEvent {
  final SignUpFormModel data;

  const AuthLogin(this.data);

  @override
  // TODO: implement props
  List<Object> get props => [data];
}

class AuthVerificationOtp extends AuthEvent {
  final OtpFormModel data;
  const AuthVerificationOtp(this.data);

  @override
  List<Object> get props => [data];
}

class AuthVerificationOtpRegister extends AuthEvent {
  final SignUpFormModel data;
  final String otp;
  const AuthVerificationOtpRegister(this.data, this.otp);

  @override
  List<Object> get props => [data, otp];
}

class AuthGetCurrentUser extends AuthEvent {}

class AuthLogout extends AuthEvent {}

class AuthUpdateStatus extends AuthEvent {
  final String status;
  final String id;
  final String latitude;
  final String longitude;
  const AuthUpdateStatus(this.status, this.id, this.latitude, this.longitude);

  @override
  // TODO: implement props

  List<Object> get props => [status, id, latitude, longitude];
}

class AuthUpdateStatusMober extends AuthEvent {
  final String id;
  final int statusMober;

  const AuthUpdateStatusMober(this.id, this.statusMober);

  @override
  List<Object> get props => [id, statusMober];
}

class AuthUserUpdate extends AuthEvent {
  final String user_id;
  final String name;
  final String image;
  final String email;

  const AuthUserUpdate(this.user_id, this.name, this.image, this.email);

  @override
  // TODO: implement props
  List<Object> get props => [user_id, name, image, email];
}
