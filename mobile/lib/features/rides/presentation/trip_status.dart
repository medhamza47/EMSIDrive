import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/marketplace_models.dart';

String tripStageLabel(AppLocalizations l, RideStage stage) => switch (stage) {
  RideStage.confirmed => l.tripReserved,
  RideStage.enRoute => l.tripDriverComing,
  RideStage.arrived => l.tripDriverArrived,
  RideStage.inProgress => l.tripInProgress,
  RideStage.completed => l.tripCompleted,
  RideStage.cancelled => l.tripCancelled,
};

String rideNoticeLabel(AppLocalizations l, RideNotice notice) =>
    switch (notice.title) {
      'CHAT_MESSAGE' => l.pushChatMessage,
      'TRIP_CANCELLED' => l.rideNoticeCancelled,
      'TRIP_STARTED' => l.rideNoticeStarted,
      'TRIP_COMPLETED' => l.rideNoticeCompleted,
      'REQUEST_ACCEPTED' => l.requestAcceptedNotice(notice.accepter),
      'OFFER_ACCEPTED' => l.offerAcceptedNotice(notice.accepter),
      'BOOKING_CONFIRMED' => l.tripBookingConfirmed,
      'RIDE_EN_ROUTE' => l.tripDriverComing,
      'RIDE_ARRIVED' => l.tripDriverArrived,
      'RIDE_IN_PROGRESS' => l.tripInProgress,
      'RIDE_COMPLETED' => l.tripCompleted,
      'RIDE_CANCELLED' => l.tripCancelled,
      'TRIP_CANCELLED' => l.rideNoticeCancelled,
      'TRIP_STARTED' => l.rideNoticeStarted,
      'TRIP_COMPLETED' => l.rideNoticeCompleted,
      'RIDE_MESSAGE' => l.tripNewMessage(notice.accepter),
      _ => l.acceptedRideTitle,
    };

Color tripStageColor(ColorScheme colors, RideStage stage) => switch (stage) {
  RideStage.cancelled => colors.error,
  RideStage.enRoute || RideStage.inProgress => colors.tertiary,
  _ => colors.primary,
};
