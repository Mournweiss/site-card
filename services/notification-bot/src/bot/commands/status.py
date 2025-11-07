# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
status command handler for notification-bot. Checks if the user is currently authorized.
"""
from telegram import Update
from telegram.ext import ContextTypes
from src.logger import get_logger

logger = get_logger("cmd.status")

async def status_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Handles /status: replies whether user is currently authorized to receive notifications.

    Parameters:
    - update: telegram.Update
    - context: telegram.ext.ContextTypes.DEFAULT_TYPE

    Returns:
    - None
    """
    user_id = update.effective_user.id
    user_auth_manager = context.bot_data.get("user_auth_manager")

    if user_auth_manager and user_auth_manager.is_authorized(user_id):
        logger.info("/status check: user is authorized")
        await update.message.reply_text("You are currently authorized to receive notifications.")

    else:
        logger.info("/status check: user is not authorized")
        await update.message.reply_text("You are not authorized. Use /start to authorize.")
