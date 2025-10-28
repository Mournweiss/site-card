from telegram import Bot
from telegram.ext import Updater
from telegram.error import TelegramError
from .commands import register_auth_handlers
from ..errors import TelegramDeliveryException
from src.handlers import user_auth_manager
from src.logger import get_logger

logger = get_logger("bot.start")

class TelegramBotWrapper:

    def __init__(self, token: str):

        if not token:
            raise ValueError("Bot token must not be empty")

        self.bot = Bot(token=token)

    def send_notification(self, message: str):
        user_ids = user_auth_manager.get_all_authorized_user_ids()

        if not user_ids:
            logger.warning("No authorized users to send notifications")
            return

        failed = 0
        for uid in user_ids:

            try:
                self.bot.send_message(chat_id=uid, text=message)

            except TelegramError as e:
                failed += 1
                logger.warning("Failed to send to user", user_id=uid, error=str(e))

        if failed:
            logger.warning("Notifications could not be delivered to some users", failed=failed)

    @staticmethod
    def run_auth_bot(config):
        logger.info("Starting Telegram poller-mode for user FSM auth...")
        updater = Updater(token=config.telegram_bot_token, use_context=True)
        dispatcher = updater.dispatcher
        register_auth_handlers(dispatcher, config)
        updater.start_polling()
        logger.info("Polling started")
        updater.idle()
