"""
Authorization manager for notification-bot Telegram users. Provides Authorization/Deauthorization/checks for use in gRPC, bot commands.
"""
import threading
from src.clients import NotificationUserRepository

class UserAuthManager:
    """
    Abstraction for Telegram user authorization to receive notifications. Relies on NotificationUserRepository for DB logic.
    """
    def __init__(self, user_repo):
        """
        Sets up manager with storage backend.

        Parameters:
        - user_repo: NotificationUserRepository - DB backend

        Returns:
        - UserAuthManager
        """
        self.user_repo = user_repo

    def is_authorized(self, user_id: int) -> bool:
        """
        Checks if user ID is currently authorized.

        Parameters:
        - user_id: int

        Returns:
        - bool
        """
        return self.user_repo.is_authorized(user_id)

    def authorize(self, user_id: int, username=None):
        """
        Adds user to authorized set (ID + optional username).

        Parameters:
        - user_id: int
        - username: str|None

        Returns:
        - None
        """
        self.user_repo.add_user(user_id, username)

    def unauthorize(self, user_id: int):
        """
        Removes user from authorization.

        Parameters:
        - user_id: int

        Returns:
        - None
        """
        self.user_repo.remove_user(user_id)

    def get_all_authorized_user_ids(self):
        """
        Returns all currently authorized Telegram user IDs.

        Parameters:
        - None

        Returns:
        - list[int]
        """
        return self.user_repo.get_all_authorized_user_ids()

# Global singleton (to be set by app at startup)
user_auth_manager = None
