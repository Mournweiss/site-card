# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Logging utilities for notification-bot with structlog and secret/token masking for security.
"""
import sys
import structlog
import logging
import re
from typing import Optional
from src.errors import TelegramDeliveryException

_config_instance = None
_debug_mode = None
_token_value = None

def set_logger_config_from_config(config):
    """
    Applies and activates logger config using global config instance; sets debug and token settings.

    Parameters:
    - config: object - must have debug, notification_bot_token

    Returns:
    - None (side effect)
    """
    global _config_instance, _debug_mode, _token_value
    _config_instance = config
    _debug_mode = getattr(config, 'debug', None)
    _token_value = getattr(config, 'notification_bot_token', None)
    _setup_logging(_debug_mode)

def _setup_logging(debug):
    log_level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=log_level
    )

def _get_logger_token():
    """
    Gets current notification_bot_token from config for masking.

    Parameters:
    - None (uses global state)

    Returns:
    - str - token

    Raises:
    - TelegramDeliveryException if unavailable
    """
    global _config_instance, _token_value

    if _token_value:
        return _token_value

    if _config_instance and hasattr(_config_instance, 'notification_bot_token'):
        return _config_instance.notification_bot_token

    raise TelegramDeliveryException("NOTIFICATION_BOT_TOKEN must be set in config")

def mask_secrets_processor(logger, method_name, event_dict):
    """
    structlog processor: finds and replaces logged Telegram tokens with <SECRET>.

    Parameters:
    - logger: structlog logger
    - method_name: str
    - event_dict: dict

    Returns:
    - dict (with sensitive values masked)
    """
    try:
        token = _get_logger_token()

    except TelegramDeliveryException:
        return event_dict

    if not token:
        return event_dict

    regex_token = re.escape(token)
    pattern_url = rf"https://api\.telegram\.org/bot{regex_token}"

    def mask_text(text):
        """
        Mask token and API URLs in provided text for logging safety.

        Parameters:
        - text: str

        Returns:
        - str (safely masked)
        """
        if not isinstance(text, str):
            return text

        masked = re.sub(regex_token, "<SECRET>", text)
        masked = re.sub(pattern_url, "https://api.telegram.org/bot[SECRET]", masked)
        return masked

    for k, v in event_dict.items():

        if isinstance(v, str):
            event_dict[k] = mask_text(v)

    if isinstance(event_dict.get("event"), str):
        event_dict["event"] = mask_text(event_dict["event"])

    return event_dict

structlog.configure(
    processors=[
        mask_secrets_processor,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

def get_logger(name=None):
    """
    Returns a structlog logger for this module, optionally with name.

    Parameters:
    - name: str|None

    Returns:
    - structlog.stdlib.BoundLogger
    """
    return structlog.get_logger(name)
