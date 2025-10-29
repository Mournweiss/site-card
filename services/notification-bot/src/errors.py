class NotificationException(Exception):
    pass

class GrpcDeliveryException(NotificationException):
    pass

class TelegramDeliveryException(NotificationException):
    pass

class AuthException(NotificationException):
    pass
