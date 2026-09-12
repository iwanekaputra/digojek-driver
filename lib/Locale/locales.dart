import 'dart:async';

import 'package:deliq_delivery/Locale/languages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static Languages language = Languages();

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': language.indonesian(),
    'en': language.english(),
    'ar': language.arabic(),
    'pt': language.portuguese(),
    'fr': language.french(),
    'es': language.spanish(),
    'tr': language.turkish(),
    'it': language.italian(),
    'sw': language.swahili(),
    'de': language.german(),
    'ro': language.romania(),
  };

  String? get invalidNumber {
    return _localizedValues[locale.languageCode]!['invalidNumber'];
  }

  String? get networkError {
    return _localizedValues[locale.languageCode]!['networkError'];
  }

  String? get register {
    return _localizedValues[locale.languageCode]!['register'];
  }

  String? get invalidName {
    return _localizedValues[locale.languageCode]!['invalidName'];
  }

  String? get invalidEmail {
    return _localizedValues[locale.languageCode]!['invalidEmail'];
  }

  String? get invalidNameAndEmail {
    return _localizedValues[locale.languageCode]!['invalidNameAndEmail'];
  }

  String? get fullName {
    return _localizedValues[locale.languageCode]!['fullName'];
  }

  String? get emailAddress {
    return _localizedValues[locale.languageCode]!['emailAddress'];
  }

  String? get mobileNumber {
    return _localizedValues[locale.languageCode]!['mobileNumber'];
  }

  String? get verificationText {
    return _localizedValues[locale.languageCode]!['verificationText'];
  }

  String? get verification {
    return _localizedValues[locale.languageCode]!['verification'];
  }

  String? get checkNetwork {
    return _localizedValues[locale.languageCode]!['checkNetwork'];
  }

  String? get invalidOTP {
    return _localizedValues[locale.languageCode]!['invalidOTP'];
  }

  String? get enterVerification {
    return _localizedValues[locale.languageCode]!['enterVerification'];
  }

  String? get verificationCode {
    return _localizedValues[locale.languageCode]!['verificationCode'];
  }

  String? get resend {
    return _localizedValues[locale.languageCode]!['resend'];
  }

  String? get offlineText {
    return _localizedValues[locale.languageCode]!['offlineText'];
  }

  String? get onlineText {
    return _localizedValues[locale.languageCode]!['onlineText'];
  }

  String? get goOnline {
    return _localizedValues[locale.languageCode]!['goOnline'];
  }

  String? get goOffline {
    return _localizedValues[locale.languageCode]!['goOffline'];
  }

  String? get orders {
    return _localizedValues[locale.languageCode]!['orders'];
  }

  String? get ride {
    return _localizedValues[locale.languageCode]!['ride'];
  }

  String? get licence {
    return _localizedValues[locale.languageCode]!['licence'];
  }

  String? get onion {
    return _localizedValues[locale.languageCode]!['onion'];
  }

  String? get cauliflower {
    return _localizedValues[locale.languageCode]!['cauliflower'];
  }

  String? get tomatoes {
    return _localizedValues[locale.languageCode]!['tomatoes'];
  }

  String? get heyThere {
    return _localizedValues[locale.languageCode]!['heyThere'];
  }

  String? get onMyWay {
    return _localizedValues[locale.languageCode]!['onMyWay'];
  }

  String? get earnings {
    return _localizedValues[locale.languageCode]!['earnings'];
  }

  String? get location {
    return _localizedValues[locale.languageCode]!['earnings'];
  }

  String? get grant {
    return _localizedValues[locale.languageCode]!['earnings'];
  }

  String? get bodyText1 {
    return _localizedValues[locale.languageCode]!['bodyText1'];
  }

  String? get bodyText2 {
    return _localizedValues[locale.languageCode]!['bodyText2'];
  }

  String? get mobileText {
    return _localizedValues[locale.languageCode]!['mobileText'];
  }

  String? get continueText {
    return _localizedValues[locale.languageCode]!['continueText'];
  }

  String? get homeText {
    return _localizedValues[locale.languageCode]!['homeText'];
  }

  String? get orderText {
    return _localizedValues[locale.languageCode]!['orderText'];
  }

  String? get tnc {
    return _localizedValues[locale.languageCode]!['tnc'];
  }

  String? get insight {
    return _localizedValues[locale.languageCode]!['insight'];
  }

  String? get wallet {
    return _localizedValues[locale.languageCode]!['wallet'];
  }

  String? get support {
    return _localizedValues[locale.languageCode]!['support'];
  }

  String? get aboutUs {
    return _localizedValues[locale.languageCode]!['aboutUs'];
  }

  String? get login {
    return _localizedValues[locale.languageCode]!['login'];
  }

  String? get logout {
    return _localizedValues[locale.languageCode]!['logout'];
  }

  String? get loggingOut {
    return _localizedValues[locale.languageCode]!['loggingOut'];
  }

  String? get areYouSure {
    return _localizedValues[locale.languageCode]!['areYouSure'];
  }

  String? get yes {
    return _localizedValues[locale.languageCode]!['yes'];
  }

  String? get no {
    return _localizedValues[locale.languageCode]!['no'];
  }

  String? get sendToBank {
    return _localizedValues[locale.languageCode]!['sendToBank'];
  }

  String? get availableBalance {
    return _localizedValues[locale.languageCode]!['availableBalance'];
  }

  String? get accountHolderName {
    return _localizedValues[locale.languageCode]!['accountHolderName'];
  }

  String? get bankName {
    return _localizedValues[locale.languageCode]!['bankName'];
  }

  String? get branchCode {
    return _localizedValues[locale.languageCode]!['branchCode'];
  }

  String? get accountNumber {
    return _localizedValues[locale.languageCode]!['accountNumber'];
  }

  String? get enterAmountToTransfer {
    return _localizedValues[locale.languageCode]!['enterAmountToTransfer'];
  }

  String? get bankInfo {
    return _localizedValues[locale.languageCode]!['bankInfo'];
  }

  String? get aboutDelivoo {
    return _localizedValues[locale.languageCode]!['aboutDelivoo'];
  }

  String? get aboutBody {
    return _localizedValues[locale.languageCode]!['aboutBody'];
  }

  String? get ourVision {
    return _localizedValues[locale.languageCode]!['ourVision'];
  }

  String? get companyPolicy {
    return _localizedValues[locale.languageCode]!['companyPolicy'];
  }

  String? get termsOfUse {
    return _localizedValues[locale.languageCode]!['termsOfUse'];
  }

  String? get message {
    return _localizedValues[locale.languageCode]!['message'];
  }

  String? get enterMessage {
    return _localizedValues[locale.languageCode]!['enterMessage'];
  }

  String? get orWrite {
    return _localizedValues[locale.languageCode]!['orWrite'];
  }

  String? get yourWords {
    return _localizedValues[locale.languageCode]!['yourWords'];
  }

  String? get online {
    return _localizedValues[locale.languageCode]!['online'];
  }

  String? get recent {
    return _localizedValues[locale.languageCode]!['recent'];
  }

  String? get vegetable {
    return _localizedValues[locale.languageCode]!['vegetable'];
  }

  String? get today {
    return _localizedValues[locale.languageCode]!['today'];
  }

  String? get viewAll {
    return _localizedValues[locale.languageCode]!['viewAll'];
  }

  String? get editProfile {
    return _localizedValues[locale.languageCode]!['editProfile'];
  }

  String? get lightText {
    return _localizedValues[locale.languageCode]!['lightText'];
  }

  String? get lightMode {
    return _localizedValues[locale.languageCode]!['lightMode'];
  }

  String? get submit {
    return _localizedValues[locale.languageCode]!['submit'];
  }

  String? get featureImage {
    return _localizedValues[locale.languageCode]!['featureImage'];
  }

  String? get uploadPhoto {
    return _localizedValues[locale.languageCode]!['uploadPhoto'];
  }

  String? get profileInfo {
    return _localizedValues[locale.languageCode]!['profileInfo'];
  }

  String? get gender {
    return _localizedValues[locale.languageCode]!['gender'];
  }

  String? get documentation {
    return _localizedValues[locale.languageCode]!['documentation'];
  }

  String? get govtID {
    return _localizedValues[locale.languageCode]!['govtID'];
  }

  String? get upload {
    return _localizedValues[locale.languageCode]!['upload'];
  }

  String? get updateInfo {
    return _localizedValues[locale.languageCode]!['updateInfo'];
  }

  String? get instruction {
    return _localizedValues[locale.languageCode]!['instruction'];
  }

  String? get cod {
    return _localizedValues[locale.languageCode]!['cod'];
  }

  String? get backToHome {
    return _localizedValues[locale.languageCode]!['backToHome'];
  }

  String? get viewEarnings {
    return _localizedValues[locale.languageCode]!['viewEarnings'];
  }

  String? get yourEarnings {
    return _localizedValues[locale.languageCode]!['yourEarnings'];
  }

  String? get youDrived {
    return _localizedValues[locale.languageCode]!['youDrived'];
  }

  String? get viewOrderInfo {
    return _localizedValues[locale.languageCode]!['viewOrderInfo'];
  }

  String? get delivered {
    return _localizedValues[locale.languageCode]!['delivered'];
  }

  String? get thankYou {
    return _localizedValues[locale.languageCode]!['thankYou'];
  }

  String? get newDeliveryTask {
    return _localizedValues[locale.languageCode]!['newDeliveryTask'];
  }

  String? get orderInfo {
    return _localizedValues[locale.languageCode]!['orderInfo'];
  }

  String? get close {
    return _localizedValues[locale.languageCode]!['close'];
  }

  String? get direction {
    return _localizedValues[locale.languageCode]!['direction'];
  }

  String? get store {
    return _localizedValues[locale.languageCode]!['store'];
  }

  String? get markPicked {
    return _localizedValues[locale.languageCode]!['markPicked'];
  }

  String? get markDelivered {
    return _localizedValues[locale.languageCode]!['markDelivered'];
  }

  String? get accept {
    return _localizedValues[locale.languageCode]!['accept'];
  }

  String? get display {
    return _localizedValues[locale.languageCode]!['display'];
  }

  String? get darkMode {
    return _localizedValues[locale.languageCode]!['darkMode'];
  }

  String? get darkText {
    return _localizedValues[locale.languageCode]!['darkText'];
  }

  String? get selectLanguage {
    return _localizedValues[locale.languageCode]!['language'];
  }

  String? get hey {
    return _localizedValues[locale.languageCode]!['hey'];
  }

  String? get settings {
    return _localizedValues[locale.languageCode]!['settings'];
  }

  String? get or {
    return _localizedValues[locale.languageCode]!['or'];
  }

  String? get continueWith {
    return _localizedValues[locale.languageCode]!['continueWith'];
  }

  String? get facebook {
    return _localizedValues[locale.languageCode]!['facebook'];
  }

  String? get google {
    return _localizedValues[locale.languageCode]!['google'];
  }

  String? get apple {
    return _localizedValues[locale.languageCode]!['apple'];
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => [
        'id',
        'en',
        'ar',
        'pt',
        'fr',
        'es',
        'tr',
        'it',
        'sw',
        'de',
        'ro'
      ].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Returning a SynchronousFuture here because an async "load" operation
    // isn't needed to produce an instance of AppLocalizations.
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
