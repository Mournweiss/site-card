import platform
import telegram
from datetime import datetime
from telegram import Update
from telegram.ext import ContextTypes
from src.logger import get_logger

logger = get_logger("cmd.about")

ABOUT_TEXT = (
    "*Notification-Bot for SiteCard platform*\n\n"
    "Delivers contact form notifications via Telegram/fan-out.\n"
    "Implements FSM authorization, gRPC interface, and professional observability.\n"
    f"\n*Python*: `{platform.python_version()}` | *PTB*: `{telegram.__version__}` "
    f"\n*Build time*: `{datetime.utcnow().isoformat()}`"
    "\n\nSupported commands: /start, /about, /cancel\n"
    "Source & docs: [GitHub/README](https://github.com/Mournweiss/site-card)"
)

async def about_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    logger.info("/about requested", user_id=user_id)
    await update.message.reply_text(ABOUT_TEXT, parse_mode='Markdown')
    return None
