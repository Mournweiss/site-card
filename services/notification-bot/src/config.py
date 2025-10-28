import os
from dataclasses import dataclass

@dataclass(frozen=True)
class Config:
    admin_key: str
    telegram_bot_token: str
    notification_bot_port: int = 50051
    debug: bool = False

    @staticmethod
    def from_env():
        missing = []
        admin_key = os.environ.get("ADMIN_KEY", "")

        if not admin_key:
            missing.append("ADMIN_KEY")

        tg_token = os.environ.get("TELEGRAM_BOT_TOKEN")

        if not tg_token:
            missing.append("TELEGRAM_BOT_TOKEN")

        notification_bot_port = int(os.environ.get("NOTIFICATION_BOT_PORT", 50051))
        debug = os.environ.get("DEBUG", "false").lower() == "true"

        if missing:
            raise RuntimeError(f"Missing config envs: {', '.join(missing)}")

        return Config(
            admin_key=admin_key,
            telegram_bot_token=tg_token,
            notification_bot_port=notification_bot_port,
            debug=debug
        )
