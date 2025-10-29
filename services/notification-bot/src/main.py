import logging
import threading
from src.config import Config
from src.errors import NotificationException
from src.bot import build_application
from src.api import serve as serve_grpc


def main():
    logging.basicConfig(level=logging.INFO)

    try:
        config = Config.from_env()

    except Exception as e:
        logging.error(f"Configuration error: {e}")
        exit(1)

    application = build_application(config)

    grpc_thread = threading.Thread(target=serve_grpc, args=(config, None), daemon=True)
    grpc_thread.start()

    application.run_polling()

if __name__ == "__main__":
    main()