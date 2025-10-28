import os
import sys
import structlog
import logging

_debug_mode = None

def set_debug_mode(debug: bool):
    global _debug_mode
    _debug_mode = debug
    _setup_logging(_debug_mode)

def _setup_logging(debug):
    log_level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=log_level
    )

set_debug_mode(os.environ.get("DEBUG", "false").lower() == "true")

structlog.configure(
    processors=[
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
    return structlog.get_logger(name)
