# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
gRPC service implementation for notification-bot (contact message, Telegram WebApp auth).
Implements NotificationDeliveryServicer from service_pb2_grpc.
"""

import grpc
from concurrent import futures
import logging
from . import service_pb2
from . import service_pb2_grpc
from ..errors import NotificationException
from ..handlers import user_auth_manager, decrypt_uid_for_webapp

logger = logging.getLogger(__name__)

class NotificationService(service_pb2_grpc.NotificationDeliveryServicer):
    """
    Implements NotificationDeliveryServicer endpoints for notification-bot.
    """

    def __init__(self, handler):
        """
        Initialize service with domain handler (delivers messages, manages auth).

        Parameters:
        - handler: object - provides deliver_contact_message(), etc

        Returns:
        - NotificationService instance
        """
        self.handler = handler

    def AuthorizeWebappUser(self, request, context):
        """
        gRPC endpoint to authorize a Telegram WebApp user.
        Sets INVALID_ARGUMENT if user_id not present; returns result OK or with error_message.

        Parameters:
        - request: WebappUserAuthRequest - incoming request from client
        - context: grpc.ServicerContext - for error status/settings

        Returns:
        - WebappUserAuthResponse: RPC result
        """
        euid = getattr(request, 'euid', None)

        if not euid:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return service_pb2.WebappUserAuthResponse(success=False, error_message="Missing euid (encrypted user_id)")

        try:
            secret = self.handler.config.webapp_token_secret
            user_id = decrypt_uid_for_webapp(euid, secret)

        except Exception as ex:
            logger.warning(f"Failed to decrypt euid for auth: {ex}")
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return service_pb2.WebappUserAuthResponse(success=False, error_message="Invalid euid or decryption failed")

        try:
            user_auth_manager.authorize(int(user_id))
            return service_pb2.WebappUserAuthResponse(success=True, error_message="")

        except Exception as ex:
            context.set_code(grpc.StatusCode.UNKNOWN)
            return service_pb2.WebappUserAuthResponse(success=False, error_message=str(ex))

    def DeliverContactMessage(self, request, context):
        """
        gRPC endpoint to send a user contact message for notification delivery.

        Parameters:
        - request: ContactMessageRequest - gRPC input message
        - context: grpc.ServicerContext

        Returns:
        - ContactMessageResponse: success/error
        """
        name = getattr(request, 'name', None)
        email = getattr(request, 'email', None)
        body = getattr(request, 'body', None)
        logger.info(f"gRPC DeliverContactMessage called", extra={"contact_name": name, "contact_email": email})

        if not (name and email and body):
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            context.set_details("Missing required fields (name, email, body)")
            return service_pb2.ContactMessageResponse(success=False, error_message="Missing required fields (name, email, body)")

        try:
            self.handler.deliver_contact_message(name, email, body)
            logger.info("Notification delivered successfully", extra={"contact_name": name, "contact_email": email})
            return service_pb2.ContactMessageResponse(success=True, error_message="")

        except NotificationException as e:
            logger.error(f"Business error while delivering contact message: {e}", exc_info=True)
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            context.set_details(str(e))
            return service_pb2.ContactMessageResponse(success=False, error_message=str(e))

        except Exception as ex:
            logger.error(f"Internal error in DeliverContactMessage: {ex}", exc_info=True)
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details("Internal error")
            return service_pb2.ContactMessageResponse(success=False, error_message="Internal server error")


def serve(config, handler):
    """
    Entrypoint for gRPC server; binds and serves NotificationService on configured port.
    Call blocks until termination and logs endpoint info.

    Parameters:
    - config: object - contains notification_bot_port attribute
    - handler: object - passed to NotificationService (domain/logic providers)

    Returns:
    - None
    """
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    service_pb2_grpc.add_NotificationDeliveryServicer_to_server(NotificationService(handler), server)
    server.add_insecure_port(f'[::]:{config.notification_bot_port}')
    server.start()
    logger.info(f'Notification gRPC Server started at {config.notification_bot_port}')
    server.wait_for_termination()
