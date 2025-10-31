import asyncio
import time
from queue import Queue, Empty
from src.logger import get_logger
from ..errors import NotificationException

class NotificationHandler:

    def __init__(self, application, user_auth_manager):
        self.application = application
        self.user_auth_manager = user_auth_manager
        self.send_queue = Queue()
        self._worker_started = False

    def deliver_contact_message(self, name: str, email: str, body: str):
        user_ids = self.user_auth_manager.get_all_authorized_user_ids()

        if not all([name, email, body]):
            raise NotificationException("All contact fields are required")

        if "@" not in email or "." not in email:
            raise NotificationException("Invalid email format")

        msg = self._render_message(name, email, body)

        for uid in user_ids:
            self.send_queue.put((uid, msg))

    async def deliver_worker(self, poll_interval=1.0):
        logger = get_logger("telegram_notify_worker")

        while True:

            try:
                uid, msg = self.send_queue.get_nowait()

                try:
                    await self.application.bot.send_message(uid, msg, parse_mode='HTML')
                    logger.info("Notification sent in worker", extra={"notify_user_id": uid})

                except Exception as ex:
                    logger.warning("Failed to deliver notification in worker", extra={"notify_user_id": uid, "notify_error": str(ex)})

            except Empty:
                await asyncio.sleep(poll_interval)

    async def start_worker(self):

        if not self._worker_started:
            self.application.create_task(self.deliver_worker())
            self._worker_started = True

    @staticmethod
    def _render_message(name, email, body):
        return (
            "New Contact Message\n\n"
            f"<b>Name:</b>\n{name}\n\n"
            f"<b>Email:</b>\n{email}\n\n"
            f"<b>Message:</b>\n{body.strip()}"
        )
