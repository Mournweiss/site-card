# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
gRPC service implementation for notification-bot (contact message, Telegram WebApp auth).
Implements NotificationDeliveryServicer from service_pb2_grpc.
"""

import grpc
import grpc.aio
import logging
import traceback
from concurrent import futures
from . import service_pb2
from . import service_pb2_grpc
from ..errors import NotificationException
from ..handlers import user_auth_manager, decrypt_uid_for_webapp

logger = logging.getLogger(__name__)

class NotificationService(service_pb2_grpc.NotificationDeliveryServicer):
    """
    Main gRPC API implementation for notification-bot business logic.
    Exposes async endpoints for Telegram WebApp user authorization and contact message delivery.
    """

    def __init__(self, config, handler):
        """
        Initialize service with domain handler (delivers messages, manages auth).

        Parameters:
        - handler: object - provides deliver_contact_message(), etc

        Returns:
        - NotificationService instance
        """
        self.config = config
        self.handler = handler

        if not hasattr(handler, "user_auth_manager") or handler.user_auth_manager is None:
            logger.error("NotificationService initialized with handler lacking user_auth_manager")

    async def AuthorizeWebappUser(self, request, context):
        """
        Handles gRPC WebApp user authorization request from app-service.
        Decrypts user_id, optionally sends success notification, and registers authorization.

        Parameters:
        - request: WebappUserAuthRequest (protobuf, includes `euid`)
        - context: grpc.aio.ServicerContext

        Returns:
        - WebappUserAuthResponse (protobuf): success/error status and error_message if failed
        """
        euid = getattr(request, 'euid', None)

        if not euid:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT, "Missing euid (encrypted user_id)")

        try:
            secret = self.config.webapp_token_secret
            logger.info(f"Decrypting euid: {euid}")   
            user_id = decrypt_uid_for_webapp(euid, secret)

        except Exception as ex:
            logger.warning(f"Failed to decrypt euid for auth: {ex}\n" + traceback.format_exc())
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT, "Invalid euid or decryption failed: " + str(ex))

        try:
            auth_manager = self.handler.user_auth_manager
            already_auth = auth_manager.is_authorized(int(user_id))

            # Call notification for first successful authorization
            if not already_auth:

                try:
                    await self.handler.send_success_auth_notification(int(user_id))

                except Exception as nerr:
                    logger.warning(f"Failed to send Telegram success notification: {nerr}", extra={"user_id": user_id})

            auth_manager.authorize(int(user_id))
            logger.info("User authorized via WebApp (feedback sent if first auth)", extra={"user_id": user_id})
            return service_pb2.WebappUserAuthResponse(success=True, error_message="")

        except Exception as ex:
            logger.error(f"Exception in user authorization: {ex}\n" + traceback.format_exc())
            await context.abort(grpc.StatusCode.UNKNOWN, "Authorization exception: " + str(ex))

    async def DeliverContactMessage(self, request, context):
        """
        Handles gRPC contact message delivery from app-service (site visitor/user).
        Validates request and enqueues delivery to all authorized Telegram users.

        Parameters:
        - request: ContactMessageRequest (protobuf) — includes `name`, `email`, `body`
        - context: grpc.aio.ServicerContext

        Returns:
        - ContactMessageResponse (protobuf): success or error status with error_message
        """
        name = getattr(request, 'name', None)
        email = getattr(request, 'email', None)
        body = getattr(request, 'body', None)
        logger.info(f"gRPC DeliverContactMessage called", extra={"contact_name": name, "contact_email": email})

        if not (name and email and body):
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT, "Missing required fields (name, email, body)")

        try:
            self.handler.deliver_contact_message(name, email, body)
            logger.info("Notification delivered successfully", extra={"contact_name": name, "contact_email": email})
            return service_pb2.ContactMessageResponse(success=True, error_message="")

        except NotificationException as e:
            logger.error(f"Business error while delivering contact message: {e}", exc_info=True)
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT, str(e))

        except Exception as ex:
            logger.error(f"Internal error in DeliverContactMessage: {ex}", exc_info=True)
            await context.abort(grpc.StatusCode.INTERNAL, "Internal server error")

async def serve(config, handler):
    """
    Entrypoint for async gRPC server; binds and serves NotificationService using asyncio event loop.

    Parameters:
    - config: Config (contains environment, port, etc)
    - handler: NotificationHandler (business logic, delivery, user tracking)

    Returns:
    - None (runs gRPC server until termination)
    """
    server = grpc.aio.server()
    service = NotificationService(config, handler)
    service_pb2_grpc.add_NotificationDeliveryServicer_to_server(service, server)
    server.add_insecure_port(f'[::]:{config.notification_bot_port}')
    logger.info(f'Async Notification gRPC Server starting at {config.notification_bot_port}')
    await server.start()
    logger.info(f'Async Notification gRPC Server started at {config.notification_bot_port}')
    await server.wait_for_termination()
