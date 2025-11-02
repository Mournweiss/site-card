"""
Logout command handler and confirmation dialog for notification-bot.
"""
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes, CallbackQueryHandler
from src.logger import get_logger

logger = get_logger("cmd.logout")

CONFIRM_LOGOUT_TEXT = "Are you sure you want to log out and stop receiving notifications?"
SUCCESS_LOGOUT_TEXT = "<b>Logout successful.</b> You will no longer receive notifications."
CANCEL_LOGOUT_TEXT = "Logout cancelled."
ALREADY_LOGGED_OUT_TEXT = "You were not authorized."
ERROR_LOGOUT_TEXT = "Unexpected error during logout. Try again later."

async def logout_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Handles /logout: prompts user for confirmation with inline Yes/No buttons.

    Parameters:
    - update: telegram.Update
    - context: telegram.ext.ContextTypes.DEFAULT_TYPE

    Returns:
    - None
    """
    keyboard = [[
        InlineKeyboardButton("Yes", callback_data="logout_yes"),
        InlineKeyboardButton("No", callback_data="logout_no")
    ]]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(CONFIRM_LOGOUT_TEXT, reply_markup=reply_markup)
    logger.info("Sent logout confirmation query", extra={"log_user_id": update.effective_user.id})


def build_logout_callback_handler():
    """
    Builds a callback handler for logout confirmation (button press).

    Parameters:
    - none (returns handler for registration)

    Returns:
    - CallbackQueryHandler: handles Yes/No confirmation for logout
    """

    async def logout_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
        """
        Nested callback: handles Yes/No inline action, manages sessions.

        Parameters:
        - update: telegram.Update
        - context: telegram.ext.ContextTypes.DEFAULT_TYPE

        Returns:
        - None
        """
        query = update.callback_query
        user_id = query.from_user.id
        logger.info(f"Received logout callback", extra={"log_user_id": user_id, "callback_data": query.data})
        user_auth_manager = context.bot_data.get("user_auth_manager")
        await query.answer()

        if query.data == "logout_yes":

            if not user_auth_manager:
                logger.error("UserAuthManager missing in context. Cannot logout (callback).", extra={"log_user_id": user_id})
                await query.edit_message_text("Internal error: Authorization manager unavailable. Contact admin.")
                return

            try:

                if user_auth_manager.is_authorized(user_id):
                    user_auth_manager.unauthorize(user_id)
                    logger.info("User logged out via callback", extra={"log_user_id": user_id})
                    await query.edit_message_text(SUCCESS_LOGOUT_TEXT, parse_mode="HTML")

                else:
                    logger.info("Logout via callback but user was not authorized", extra={"log_user_id": user_id})
                    await query.edit_message_text(ALREADY_LOGGED_OUT_TEXT)

            except Exception as ex:
                logger.error("Exception during logout callback", extra={"log_user_id": user_id, "logout_error": str(ex)})
                await query.edit_message_text(ERROR_LOGOUT_TEXT)

        elif query.data == "logout_no":
            logger.info("Logout cancelled by user via callback", extra={"log_user_id": user_id})
            await query.edit_message_text(CANCEL_LOGOUT_TEXT, parse_mode="HTML")

    return CallbackQueryHandler(logout_callback, pattern="^logout_(yes|no)$")
