# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Main entrypoint for notification-bot, initializes config, handlers, Telegram app, gRPC server.
"""
import logging
import threading
import asyncio
import atexit
from src.config import Config
from src.errors import NotificationException
from src.clients import NotificationUserRepository
from src.handlers import UserAuthManager, user_auth_manager as global_user_auth_manager
from src.bot import build_application
from src.api import serve
from src.handlers import NotificationHandler

def main():
    """
    Initializes and runs all notification-bot systems: config, Telegram bot, notification handler, and gRPC server.
    Registers cleanup for DB repo, starts async notification delivery and polling.

    Parameters:
    - None

    Returns:
    - None
    """
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
        """
        Ensures DB connection is closed on process exit (atexit handler).

        Parameters:
        - None

        Returns:
        - None
        """
        user_repo.close()

    atexit.register(close_repo)

    # Build and register Telegram app, data and notification handler
    application = build_application(config, global_user_auth_manager)
    handler = NotificationHandler(application, global_user_auth_manager)
    application.bot_data["notification_handler"] = handler

    # Run delivery worker
    async def startup_callback(app):
        """
        Starts background delivery worker after Telegram Application event loop is running.

        Parameters:
        - app: telegram.ext.Application

        Returns:
        - None
        """
        handler = app.bot_data["notification_handler"]
        await handler.start_worker()

    application.post_init = startup_callback

    # Run async gRPC server
    def grpc_target():
        """
        Runs async gRPC notification server in a separate thread using asyncio event loop.

        Parameters:
        - None

        Returns:
        - None
        """
        asyncio.run(serve(config, handler))

    grpc_thread = threading.Thread(target=grpc_target, daemon=True)
    grpc_thread.start()

    application.run_polling()

if __name__ == "__main__":
    main()