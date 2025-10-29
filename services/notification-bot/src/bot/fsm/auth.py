from telegram import Update, ReplyKeyboardRemove
from telegram.ext import ConversationHandler, MessageHandler, CommandHandler, ContextTypes, filters
from src.logger import get_logger
from src.handlers import user_auth_manager

logger = get_logger("fsm.auth")
WAIT_KEY = 1

async def fsm_check_key(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    key = update.message.text.strip()
    context.user_data["attempts"] = context.user_data.get("attempts", 0) + 1
    logger.info("FSM_CHECK_KEY_ENTERED", user_id=user_id, text=key, attempt=context.user_data["attempts"], state="WAIT_KEY")
    config = context.bot_data["config"]
    attempt = context.user_data["attempts"]

    if key == config.admin_key:
        user_auth_manager.authorize(user_id)
        logger.info("User authorized", user_id=user_id, attempts=attempt)
        await update.message.reply_text("Authorized.", reply_markup=ReplyKeyboardRemove())
        return ConversationHandler.END

    else:
        logger.warning("Auth failed", user_id=user_id, attempts=attempt)

        if context.user_data["attempts"] >= 3:
            await update.message.reply_text("Failed. Too many attempts.", reply_markup=ReplyKeyboardRemove())
            return ConversationHandler.END

        await update.message.reply_text("Incorrect key. Please try again:")
        return WAIT_KEY

async def fsm_cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    logger.info("FSM auth cancelled", user_id=user_id)
    await update.message.reply_text("Cancelled.", reply_markup=ReplyKeyboardRemove())
    return ConversationHandler.END

def get_fsm_auth_states_and_fallbacks(config):
    return {
        WAIT_KEY: [MessageHandler(filters.TEXT & ~filters.COMMAND, fsm_check_key)],
    }, [CommandHandler("cancel", fsm_cancel)]
