import psycopg2
import psycopg2.extras
import datetime
from typing import Optional, List

class NotificationUserRepository:

    def __init__(self, config):
        self.config = config
        self._conn = None

    def _get_conn(self):

        if self._conn is None or self._conn.closed:
            self._conn = psycopg2.connect(
                host=self.config.pg_host,
                port=self.config.pg_port,
                user=self.config.pg_user,
                password=self.config.pg_password,
                dbname=self.config.pg_database,
                connect_timeout=3
            )

        return self._conn

    def add_user(self, user_id: int, username: Optional[str] = None):
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('''
                INSERT INTO authorized_bot_users (user_id, username, authorized_at) 
                VALUES (%s, %s, %s)
                ON CONFLICT (user_id) DO UPDATE SET username=EXCLUDED.username, authorized_at=EXCLUDED.authorized_at;
            ''', (user_id, username, datetime.datetime.utcnow()))
            conn.commit()

    def remove_user(self, user_id: int):
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('DELETE FROM authorized_bot_users WHERE user_id=%s', (user_id,))
            conn.commit()

    def is_authorized(self, user_id: int) -> bool:
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('SELECT 1 FROM authorized_bot_users WHERE user_id=%s LIMIT 1', (user_id,))
            return cur.fetchone() is not None

    def get_all_authorized_user_ids(self) -> List[int]:
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('SELECT user_id FROM authorized_bot_users')
            return [row[0] for row in cur.fetchall()]

    def close(self):

        if self._conn:
            self._conn.close()
            self._conn = None
