# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Exception hierarchy for notification-bot.
"""

class NotificationException(Exception):
    """Base exception for all notification-bot errors."""
    pass

class GrpcDeliveryException(NotificationException):
    """Raised for failures during gRPC delivery."""
    pass

class TelegramDeliveryException(NotificationException):
    """Raised for failures in Telegram delivery (API errors, etc)."""
    pass

class AuthException(NotificationException):
    """Raised for errors in authorization handling."""
    pass
