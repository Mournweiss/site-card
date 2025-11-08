# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Start command handler for notification-bot. Offers WebApp auth button via /start.
"""
import time
from telegram import Update, KeyboardButton, ReplyKeyboardMarkup, WebAppInfo
from telegram.ext import ContextTypes
from src.logger import get_logger
from src.handlers import generate_login_token, get_webapp_url, encrypt_uid

logger = get_logger("cmd.start")

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
    config = context.bot_data.get("config")
    euid = encrypt_uid(user_id, config.webapp_token_secret)
    token = generate_login_token(euid, config.webapp_token_secret)
    webapp_url = get_webapp_url(config.domain, euid, token, config.webapp_token_secret)
    logger.info("/start issued WebApp button", extra={"webapp_url": webapp_url})
    button = KeyboardButton(text="Authorize via WebApp", web_app=WebAppInfo(url=webapp_url))
    keyboard = ReplyKeyboardMarkup([[button]], resize_keyboard=True)
    welcome = (
        "Welcome to Notification-Bot.\n"
        "Please authorize using the button below."
    )

    await update.message.reply_text(welcome, reply_markup=keyboard)
