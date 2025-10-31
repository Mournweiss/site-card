import logging
import threading
from src.config import Config
from src.errors import NotificationException
from src.clients import NotificationUserRepository
from src.handlers import UserAuthManager, user_auth_manager as global_user_auth_manager
from src.bot import build_application
from src.api import serve as serve_grpc
import atexit


def main():
    logging.basicConfig(level=logging.INFO)

    try:
        config = Config.from_env()

    except Exception as e:
        logging.error(f"Configuration error: {e}")
        exit(1)

    user_repo = NotificationUserRepository(config)
    global global_user_auth_manager
    global_user_auth_manager = UserAuthManager(user_repo)

    def close_repo():
        user_repo.close()

    atexit.register(close_repo)
    application = build_application(config, global_user_auth_manager)

    from src.handlers import NotificationHandler
    handler = NotificationHandler(application, global_user_auth_manager)
    application.bot_data["notification_handler"] = handler

    import asyncio
    application.job_queue.run_once(lambda ctx: asyncio.create_task(handler.start_worker()), 0)

    grpc_thread = threading.Thread(target=serve_grpc, args=(config, handler), daemon=True)
    grpc_thread.start()

    application.run_polling()

if __name__ == "__main__":
    main()