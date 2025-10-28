from ..errors import NotificationException

class NotificationHandler:
    
    def __init__(self, bot):
        self.bot = bot

    def deliver_contact_message(self, name: str, email: str, body: str):
        # Simple validation
        if not all([name, email, body]):
            raise NotificationException("All contact fields are required.")
        if "@" not in email or "." not in email:
            raise NotificationException("Invalid email format.")
        msg = self._render_message(name, email, body)
        self.bot.send_notification(msg)

    @staticmethod
    def _render_message(name, email, body):
        return f"[New Contact Form]\nName: {name}\nEmail: {email}\nBody:\n{body}"
