import os
from dataclasses import dataclass

@dataclass(frozen=True)
class Config:
    admin_key: str
    notification_bot_token: str
    notification_bot_port: int = 50051
    debug: bool = False
    domain: str = ""

    @staticmethod
    def from_env():
        missing = []
        admin_key = os.environ.get("ADMIN_KEY", "")

        if not admin_key:
            missing.append("ADMIN_KEY")

        bot_token = os.environ.get("NOTIFICATION_BOT_TOKEN")

        if not bot_token:
            missing.append("NOTIFICATION_BOT_TOKEN")

        notification_bot_port = int(os.environ.get("NOTIFICATION_BOT_PORT", 50051))
        debug = os.environ.get("DEBUG", "false").lower() == "true"
        domain = os.environ.get("DOMAIN", "")

        if missing:
            raise RuntimeError(f"Missing config envs: {', '.join(missing)}")

        return Config(
            admin_key=admin_key,
            notification_bot_token=bot_token,
            notification_bot_port=notification_bot_port,
            debug=debug,
            domain=domain
        )

    @property
    def webapp_url(self):

        if self.domain:
            return f"https://{self.domain}/auth/notification"

        return ""
