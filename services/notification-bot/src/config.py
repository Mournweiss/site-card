# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Typed configuration and .env loader for notification-bot.
"""
import os
import base64
from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class Config:
    """
    Typed configuration for bot env and DB, loaded at startup. Fields:
    - admin_key: base64-encoded string of private key
    - notification_bot_token: str
    - notification_bot_port: int (default 50051)
    - debug: bool
    - domain: str (for webapp_url)
    - pg_host: str
    - pg_port: int
    - pg_user: str
    - pg_password: str
    - pg_database: str
    """
    admin_key: str
    notification_bot_token: str
    notification_bot_port: int = 50051
    debug: bool = False
    domain: str = ""
    pg_host: str = "localhost"
    pg_port: int = 5432
    pg_user: str = "postgres"
    pg_password: str = "postgres"
    pg_database: str = "sitecard"

    @staticmethod
    def from_env():
        """
        Loads config from environment and provides type validation.

        Parameters:
        - None (pulls os.environ)

        Returns:
        - Config instance

        Raises:
        - RuntimeError if any required key missing
        """
        missing = []
        private_key_path = os.environ.get("PRIVATE_KEY_PATH")

        if not private_key_path:
            missing.append("PRIVATE_KEY_PATH")

        bot_token = os.environ.get("NOTIFICATION_BOT_TOKEN")

        if not bot_token:
            missing.append("NOTIFICATION_BOT_TOKEN")

        notification_bot_port = int(os.environ.get("NOTIFICATION_BOT_PORT", 50051))
        debug = os.environ.get("DEBUG", "false").lower() == "true"
        domain = os.environ.get("DOMAIN", "")
        pg_host = os.environ.get("PGHOST", "localhost")
        pg_port = int(os.environ.get("PGPORT", 5432))
        pg_user = os.environ.get("PGUSER", "postgres")
        pg_password = os.environ.get("PGPASSWORD", "postgres")
        pg_database = os.environ.get("PGDATABASE", "sitecard")

        if not pg_host:
            missing.append("PGHOST")

        if not pg_user:
            missing.append("PGUSER")

        if not pg_password:
            missing.append("PGPASSWORD")

        if not pg_database:
            missing.append("PGDATABASE")

        if missing:
            raise RuntimeError(f"Missing config envs: {', '.join(missing)}")

        try:
            with open(private_key_path, "rb") as f:
                admin_key = base64.b64encode(f.read()).decode('ascii').replace('\n','')

        except Exception as e:
            raise RuntimeError(f"Failed to read private key from {private_key_path}: {e}")

        return Config(
            admin_key=admin_key,
            notification_bot_token=bot_token,
            notification_bot_port=notification_bot_port,
            debug=debug,
            domain=domain,
            pg_host=pg_host,
            pg_port=pg_port,
            pg_user=pg_user,
            pg_password=pg_password,
            pg_database=pg_database,
        )

    @property
    def webapp_url(self):
        """
        Computes Telegram WebApp auth URL using configured domain (if present).

        Parameters:
        - None

        Returns:
        - str - full https URL for bot WebApp auth
        """
        if self.domain:
            return f"https://{self.domain}/auth/webapp"

        return ""
