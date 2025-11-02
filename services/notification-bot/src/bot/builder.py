"""
Builder for initializing Telegram Application with handlers for notification-bot.
"""
from telegram.ext import ApplicationBuilder, CommandHandler
from .commands import start_handler, about_handler, logout_handler, build_logout_callback_handler
from src.logger import get_logger
from src.handlers import user_auth_manager

def build_application(config, user_auth_manager_instance=None):
    """
    Initializes and configures all command/callback handlers for the Telegram bot.

    Parameters:
    - config: object - config with notification_bot_token (string)
    - user_auth_manager_instance: object (optional) - DB/session manager for auth

    Returns:
    - telegram.ext.Application - application with all handlers/bot data set
    """
    logger = get_logger("builder")
    application = ApplicationBuilder().token(config.notification_bot_token).build()
    application.bot_data["config"] = config

    # Inject user authorization management
    if user_auth_manager_instance:
        application.bot_data["user_auth_manager"] = user_auth_manager_instance

    # Register command handlers
    application.add_handler(CommandHandler("start", start_handler))
    logger.info("Registered /start handler")

    application.add_handler(CommandHandler("about", about_handler))
    logger.info("Registered /about handler")

    application.add_handler(CommandHandler("logout", logout_handler))
    application.add_handler(build_logout_callback_handler())
    logger.info("Registered /logout handler and callback handler")

    return application
