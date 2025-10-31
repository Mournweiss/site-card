import threading
from src.clients import NotificationUserRepository

class UserAuthManager:

    def __init__(self, user_repo):
        self.user_repo = user_repo

    def is_authorized(self, user_id: int) -> bool:
        return self.user_repo.is_authorized(user_id)

    def authorize(self, user_id: int, username=None):
        self.user_repo.add_user(user_id, username)

    def unauthorize(self, user_id: int):
        self.user_repo.remove_user(user_id)

    def get_all_authorized_user_ids(self):
        return self.user_repo.get_all_authorized_user_ids()

user_auth_manager = None
