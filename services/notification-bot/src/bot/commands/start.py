from telegram import Update, ReplyKeyboardRemove
from telegram.ext import ContextTypes
from src.logger import get_logger
from src.bot.fsm import WAIT_KEY

logger = get_logger("cmd.start")

WELCOME_TEXT = (
    "Welcome to Notification-Bot!\nTo receive notifications, please authorize by entering the admin key after the next prompt.\n\nYou can cancel authorization anytime by sending /cancel."
)

async def start_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    logger.info("/start received", user_id=user_id)
    await update.message.reply_text(WELCOME_TEXT, reply_markup=ReplyKeyboardRemove())
    return WAIT_KEY
