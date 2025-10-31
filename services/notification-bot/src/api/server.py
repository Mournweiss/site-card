import grpc
from concurrent import futures
import logging
from . import service_pb2
from . import service_pb2_grpc
from ..errors import NotificationException
from ..handlers import user_auth_manager

logger = logging.getLogger(__name__)

class NotificationService(service_pb2_grpc.NotificationDeliveryServicer):

    def __init__(self, handler):
        self.handler = handler

    def AuthorizeWebappUser(self, request, context):
        user_id = getattr(request, 'user_id', None)
        username = getattr(request, 'username', None)

        if not user_id:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return service_pb2.WebappUserAuthResponse(success=False, error_message="Missing user_id")

        try:
            user_auth_manager.authorize(int(user_id), username)
            return service_pb2.WebappUserAuthResponse(success=True, error_message="")

        except Exception as ex:
            context.set_code(grpc.StatusCode.UNKNOWN)
            return service_pb2.WebappUserAuthResponse(success=False, error_message=str(ex))

    def DeliverContactMessage(self, request, context):
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
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    service_pb2_grpc.add_NotificationDeliveryServicer_to_server(NotificationService(handler), server)
    server.add_insecure_port(f'[::]:{config.notification_bot_port}')
    server.start()
    logger.info(f'Notification gRPC Server started at {config.notification_bot_port}')
    server.wait_for_termination()
