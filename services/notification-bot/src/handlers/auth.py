import threading

class UserAuthManager:

    def __init__(self):
        self._lock = threading.Lock()
        self._auth = {}

    def is_authorized(self, user_id: int) -> bool:
        with self._lock:
            return self._auth.get(user_id, False)

    def authorize(self, user_id: int):
        with self._lock:
            self._auth[user_id] = True

    def unauthorize(self, user_id: int):
        with self._lock:
            self._auth[user_id] = False

    def get_all_authorized_user_ids(self):
        with self._lock:
            return [uid for uid, val in self._auth.items() if val]

    def reset(self):
        with self._lock:
            self._auth = {}

user_auth_manager = UserAuthManager()
