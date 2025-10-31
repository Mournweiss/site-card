from telegram.ext import ApplicationBuilder, CommandHandler
from .commands import start_handler, about_handler
from src.logger import get_logger
from src.handlers import user_auth_manager

def build_application(config, user_auth_manager_instance=None):
    logger = get_logger("builder")
    application = ApplicationBuilder().token(config.notification_bot_token).build()
    application.bot_data["config"] = config

    if user_auth_manager_instance:
        application.bot_data["user_auth_manager"] = user_auth_manager_instance

    application.add_handler(CommandHandler("start", start_handler))
    logger.info("Registered /start handler")
    application.add_handler(CommandHandler("about", about_handler))
    logger.info("Registered /about handler")

    return application
