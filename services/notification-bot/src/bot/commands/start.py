"""
Start command handler for notification-bot. Offers WebApp auth button via /start.
"""
from telegram import Update, KeyboardButton, ReplyKeyboardMarkup, WebAppInfo
from telegram.ext import ContextTypes
from src.logger import get_logger

logger = get_logger("cmd.start")

def get_webapp_url(config):
    """
    Extracts WebApp URL from config for authorization button.

    Parameters:
    - config: object - bot config; may have .webapp_url

    Returns:
    - str: webapp URL or empty string if missing
    """
    return getattr(config, "webapp_url", "") or ""

async def start_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Handles /start: sends welcome + WebApp authorize button to user.

    Parameters:
    - update: telegram.Update - update object
    - context: telegram.ext.ContextTypes.DEFAULT_TYPE - bot context

    Returns:
    - None
    """
    user_id = update.effective_user.id
    username = update.effective_user.username
    config = context.bot_data.get("config")
    WEBAPP_URL = get_webapp_url(config)
    logger.info("/start received - sent WebApp button", extra={"log_user_id": user_id, "webapp_url": WEBAPP_URL})
    button = KeyboardButton(text="Authorize via WebApp", web_app=WebAppInfo(url=WEBAPP_URL))
    keyboard = ReplyKeyboardMarkup([[button]], resize_keyboard=True)
    welcome = (
        "Welcome to Notification-Bot.\n"
        "Please authorize using the button below."
    )

    await update.message.reply_text(welcome, reply_markup=keyboard)
