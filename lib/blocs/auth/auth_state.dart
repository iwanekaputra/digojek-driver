part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthFailed extends AuthState {
  final String e;
  const AuthFailed(this.e);

  @override
  List<Object> get props => [e];
}

final class AuthSuccess extends AuthState {
  final UserModel user;

  const AuthSuccess(this.user);

  @override
  // TODO: implement props
  List<Object> get props => [user];
}

final class AuthSuccessRegister extends AuthState {}

final class AuthSuccessVerificationOtp extends AuthState {}

final class AuthSuccessVerificationOtpRegister extends AuthState {}

final class AuthFailedVerificationOtpRegister extends AuthState {
  final String e;
  const AuthFailedVerificationOtpRegister(this.e);

  @override
  List<Object> get props => [e];
}

final class AuthFailedVerificationOtp extends AuthState {
  final String e;
  const AuthFailedVerificationOtp(this.e);

  @override
  List<Object> get props => [e];
}

final class AuthSendOtp extends AuthState {
  final String nohp;

  const AuthSendOtp(this.nohp);

  @override
  // TODO: implement props
  List<Object> get props => [nohp];
}
