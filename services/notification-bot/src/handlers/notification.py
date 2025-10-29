from ..errors import NotificationException

class NotificationHandler:

    def __init__(self, application):
        self.application = application

    def deliver_contact_message(self, name: str, email: str, body: str):

        if not all([name, email, body]):
            raise NotificationException("All contact fields are required")

        if "@" not in email or "." not in email:
            raise NotificationException("Invalid email format")

        msg = self._render_message(name, email, body)

        from src.handlers.auth import user_auth_manager
        user_ids = user_auth_manager.get_all_authorized_user_ids()

        for uid in user_ids:

            try:
                self.application.create_task(self.application.bot.send_message(uid, msg))

            except Exception as ex:
                from src.logger import get_logger
                logger = get_logger("telegram_notify")
                logger.warning("Failed to deliver notification", user_id=uid, error=str(ex))

    @staticmethod
    def _render_message(name, email, body):
        return f"[New Contact Form]\nName: {name}\nEmail: {email}\nBody:\n{body}"
