from telegram.ext import ApplicationBuilder, CommandHandler, ConversationHandler
from .commands import start_handler, about_handler
from .fsm import get_fsm_auth_states_and_fallbacks, WAIT_KEY
from src.logger import get_logger

def build_application(config):
    logger = get_logger("builder")
    application = ApplicationBuilder().token(config.notification_bot_token).build()

    states, fallbacks = get_fsm_auth_states_and_fallbacks(config)
    fsm_handler = ConversationHandler(
        entry_points=[CommandHandler("start", start_handler)],
        states=states,
        fallbacks=fallbacks,
        allow_reentry=True,
    )

    application.add_handler(fsm_handler)
    application.bot_data["config"] = config
    logger.info("Registered FSM admin authentication handler via /start")

    application.add_handler(CommandHandler("about", about_handler))
    logger.info("Registered /about handler")

    return application
