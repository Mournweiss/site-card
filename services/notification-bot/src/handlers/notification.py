# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Notification delivery handler, manages delivery queue, input validation, and async delivery to authorized Telegram users.
"""
import asyncio
import time
from queue import Queue, Empty
from src.logger import get_logger
from ..errors import NotificationException

class NotificationHandler:
    """
    Handles enqueuing and async delivery of contact notifications to authorized Telegram users.
    Provides input validation, message rendering, threaded queue, and background polling.
    """

    def __init__(self, application, user_auth_manager):
        """
        Initialize handler with bot Application and authorization manager.

        Parameters:
        - application: telegram.Application - main bot
        - user_auth_manager: UserAuthManager - manages authorized user IDs

        Returns:
        - NotificationHandler
        """
        self.application = application
        self.user_auth_manager = user_auth_manager
        self.send_queue = Queue()
        self._worker_started = False

    def deliver_contact_message(self, name: str, email: str, body: str):
        """
        Validates and enqueues a contact message for delivery to all authorized users.

        Parameters:
        - name: str - sender name
        - email: str - sender email
        - body: str - message content

        Returns:
        - None (enqueues message)

        Raises:
        - NotificationException if fields are missing or invalid
        """
        user_ids = self.user_auth_manager.get_all_authorized_user_ids()

        if not all([name, email, body]):
            raise NotificationException("All contact fields are required")

        if "@" not in email or "." not in email:
            raise NotificationException("Invalid email format")

        msg = self._render_message(name, email, body)

        for uid in user_ids:
            self.send_queue.put((uid, msg))

    async def deliver_worker(self, poll_interval=1.0):
        """
        Async worker: polls queue, delivers notifications in background.

        Parameters:
        - poll_interval: float - sleep time if queue empty

        Returns:
        - None
        """
        logger = get_logger("telegram_notify_worker")

        logger.info("delivery worker started")

        while True:

            try:
                uid, msg = self.send_queue.get_nowait()
                logger.info(f"delivery worker got message for user", extra={"notify_user_id": uid})

                try:
                    await self.application.bot.send_message(uid, msg, parse_mode='HTML')
                    logger.info("Notification sent in worker")

                except Exception as ex:
                    logger.warning("Failed to deliver notification in worker", extra={"notify_error": str(ex)})

            except Empty:
                await asyncio.sleep(poll_interval)

    async def start_worker(self):
        """
        Starts the async delivery worker loop as background task (idempotent).

        Parameters:
        - None

        Returns:
        - None
        """
        if not self._worker_started:
            self.application.create_task(self.deliver_worker())
            self._worker_started = True

    async def send_success_auth_notification(self, user_id: int):
        """
        Sends a notification message to the user about successful authorization.

        Parameters:
            user_id (int): Telegram user ID

        Returns: None
        """
        logger = get_logger("success_auth_notification")
        message = "You have successfully authorized.\nYou will now receive notifications from SiteCard."

        try:
            await self.application.bot.send_message(user_id, message)
            logger.info("Sent WebApp success auth message")

        except Exception as ex:
            logger.warning("Failed to deliver success auth notification", extra={"error": str(ex)})

    @staticmethod
    def _render_message(name, email, body):
        """
        Formats a notification message for Telegram delivery.

        Parameters:
        - name: str
        - email: str
        - body: str

        Returns:
        - str - HTML-formatted notification body for Telegram
        """
        return (
            "New Contact Message\n\n"
            f"<b>Name:</b>\n{name}\n\n"
            f"<b>Email:</b>\n{email}\n\n"
            f"<b>Message:</b>\n{body.strip()}"
        )
