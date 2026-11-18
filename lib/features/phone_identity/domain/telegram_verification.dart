import 'package:equatable/equatable.dart';

/// Server-side state of a `phone_verifications/{id}` document.
///
/// Mirrors `SessionStatus` in `functions/src/verification/session.ts`.
enum TelegramVerificationStatus {
  /// Created by the app; the user has not opened the bot yet.
  pending('pending'),

  /// The bot has been opened and is waiting for the user to share their number.
  awaitingContact('awaiting_contact'),

  verified('verified'),
  failed('failed');

  const TelegramVerificationStatus(this.storageKey);
  final String storageKey;

  bool get isTerminal => this == verified || this == failed;

  static TelegramVerificationStatus parse(Object? raw) {
    for (final status in values) {
      if (status.storageKey == raw) return status;
    }
    // An unknown value from a newer backend: treat as still in progress rather
    // than failing the user.
    return pending;
  }
}

/// What a session is for. Mirrors `SessionPurpose` on the backend.
enum TelegramSessionPurpose {
  /// Attach a number to the account that is already signed in.
  verify('verify'),

  /// "Continue with Telegram": sign into (or create) the number's account.
  signIn('signin');

  const TelegramSessionPurpose(this.storageKey);
  final String storageKey;
}

/// Why a session failed. Mirrors `FailureReason` on the backend.
enum TelegramVerificationFailure {
  expired('expired'),
  phoneInUse('phone_in_use'),
  accountError('account_error'),
  unknown('unknown');

  const TelegramVerificationFailure(this.storageKey);
  final String storageKey;

  static TelegramVerificationFailure parse(Object? raw) {
    for (final reason in values) {
      if (reason.storageKey == raw) return reason;
    }
    return unknown;
  }

  String get message => switch (this) {
        expired =>
          'The Telegram link expired before you shared your number. Try again.',
        phoneInUse =>
          'That number is already linked to another HisabET account. '
              'If it is yours, sign in to that account instead.',
        accountError =>
          'Your account could not be created. Please try again in a minute.',
        unknown => 'Telegram verification failed. Please try again.',
      };
}

class TelegramVerificationSession extends Equatable {
  const TelegramVerificationSession({
    required this.id,
    required this.status,
    this.failure,
    this.phone,
  });

  factory TelegramVerificationSession.fromMap(
    String id,
    Map<String, dynamic>? data,
  ) {
    final status = TelegramVerificationStatus.parse(data?['status']);
    return TelegramVerificationSession(
      id: id,
      status: status,
      failure: status == TelegramVerificationStatus.failed
          ? TelegramVerificationFailure.parse(data?['failureReason'])
          : null,
      phone: data?['phone'] as String?,
    );
  }

  final String id;
  final TelegramVerificationStatus status;
  final TelegramVerificationFailure? failure;

  /// The verified E.164 number, once [status] is verified.
  final String? phone;

  @override
  List<Object?> get props => [id, status, failure, phone];
}
