import grpc
from concurrent import futures
from . import service_pb2
from . import service_pb2_grpc
from ..errors import NotificationException
from ..handlers.auth import user_auth_manager

class NotificationService(service_pb2_grpc.NotificationDeliveryServicer):

    def __init__(self, handler):
        self.handler = handler

    def Notify(self, request, context):

        try:
            self.handler.handle_notification(request)
            return service_pb2.NotifyResponse(success=True)

        except NotificationException as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return service_pb2.NotifyResponse(success=False, error=str(e))

        except Exception as e:
            context.set_code(grpc.StatusCode.UNKNOWN)
            context.set_details(str(e))
            return service_pb2.NotifyResponse(success=False, error='Internal error')

    def AuthorizeWebappUser(self, request, context):
        user_id = getattr(request, 'user_id', None)
        username = getattr(request, 'username', None)

        if not user_id:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return service_pb2.WebappUserAuthResponse(success=False, error_message="Missing user_id")

        try:
            user_auth_manager.authorize(int(user_id))
            return service_pb2.WebappUserAuthResponse(success=True, error_message="")

        except Exception as ex:
            context.set_code(grpc.StatusCode.UNKNOWN)
            return service_pb2.WebappUserAuthResponse(success=False, error_message=str(ex))

def serve(config, handler):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    service_pb2_grpc.add_NotificationDeliveryServicer_to_server(NotificationService(handler), server)
    server.add_insecure_port(f'[::]:{config.notification_bot_port}')
    server.start()
    print(f'Notification gRPC Server started at {config.notification_bot_port}')
    server.wait_for_termination()
