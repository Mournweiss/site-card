from telegram import Update, ReplyKeyboardRemove
from telegram.ext import ConversationHandler, CommandHandler, MessageHandler, Filters, CallbackContext
from src.errors import AuthException
from src.handlers import user_auth_manager
from src.logger import get_logger

logger = get_logger("bot.commands")

WAIT_KEY = 1

def start(update: Update, context: CallbackContext):
    user_id = update.effective_user.id
    context.user_data["attempts"] = 0
    logger.info("FSM start invoked", user_id=user_id)
    update.message.reply_text(
        "Welcome! Please authorize yourself. Enter the admin key:", reply_markup=ReplyKeyboardRemove()
    )

    return WAIT_KEY

def check_key(update: Update, context: CallbackContext):
    user_id = update.effective_user.id
    key = update.message.text.strip()
    context.user_data["attempts"] += 1
    attempt = context.user_data["attempts"]
    config = context.bot_data["config"]

    if key == config.admin_key:
        user_auth_manager.authorize(user_id)
        logger.info("User successfully authorized", user_id=user_id, attempts=attempt)

        update.message.reply_text(
            "Authorization successful. Please standby for incoming notifications.", reply_markup=ReplyKeyboardRemove()
        )

        return ConversationHandler.END

    else:
        logger.warning("User failed auth attempt", user_id=user_id, attempts=attempt)

        if context.user_data["attempts"] >= 3:
            logger.warning("User exceeded max auth attempts", user_id=user_id)
            update.message.reply_text("Authorization failed. Too many attempts.", reply_markup=ReplyKeyboardRemove())
            return ConversationHandler.END

        update.message.reply_text(
            "Incorrect key. Please try again:"
        )

        return WAIT_KEY

def cancel(update: Update, context: CallbackContext):
    user_id = update.effective_user.id
    logger.info("User cancelled auth dialog", user_id=user_id)
    update.message.reply_text("Authorization cancelled.", reply_markup=ReplyKeyboardRemove())
    return ConversationHandler.END

def register_auth_handlers(dispatcher, config):
    handler = ConversationHandler(
        entry_points=[CommandHandler("start", start)],
        states={WAIT_KEY: [MessageHandler(Filters.text & ~Filters.command, check_key)]},
        fallbacks=[CommandHandler("cancel", cancel)],
        allow_reentry=True
    )

    dispatcher.add_handler(handler)
    dispatcher.bot_data["config"] = config
