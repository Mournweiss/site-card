import grpc
from concurrent import futures
from proto_context import service_pb2, service_pb2_grpc
from src.config import Config
from src.errors import NotificationException, GrpcDeliveryException
from src.bot import TelegramBotWrapper
from src.handlers import NotificationHandler
from src.logger import get_logger, set_debug_mode

logger = get_logger("main")

logger.info("notification-bot initializing ...")

try:
    config = Config.from_env()
    set_debug_mode(config.debug)
    bot = TelegramBotWrapper(config.telegram_bot_token)
    handler = NotificationHandler(bot)

except Exception as e:
    logger.error("Could not start notification-bot", error=str(e))
    exit(1)

class NotificationDeliveryServicer(service_pb2_grpc.NotificationDeliveryServicer):

    def DeliverContactMessage(self, request, context):

        if request.admin_key != config.admin_key:
            context.set_code(grpc.StatusCode.PERMISSION_DENIED)
            return service_pb2.ContactMessageResponse(success=False, error_message="Unauthorized")

        try:
            handler.deliver_contact_message(request.name, request.email, request.body)
            return service_pb2.ContactMessageResponse(success=True)

        except NotificationException as e:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return service_pb2.ContactMessageResponse(success=False, error_message=str(e))
            
        except Exception as e:
            logger.exception("Internal notification error", error=str(e))
            context.set_code(grpc.StatusCode.UNKNOWN)
            return service_pb2.ContactMessageResponse(success=False, error_message="Internal notification error")

def start_server():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=8))
    service_pb2_grpc.add_NotificationDeliveryServicer_to_server(NotificationDeliveryServicer(), server)
    server.add_insecure_port(f"[::]:{config.notification_bot_port}")
    server.start()
    logger.info("Notification-bot running", port=config.notification_bot_port)
    server.wait_for_termination()

if __name__ == "__main__":
    start_server()