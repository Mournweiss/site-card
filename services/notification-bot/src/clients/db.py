# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
DB client for user auth, manages authorized_bot_users (add, remove, check, list).
"""
import psycopg2
import psycopg2.extras
import datetime
from typing import Optional, List

class NotificationUserRepository:
    """
    Repository for controlling Telegram user authorization for notifications.
    Handles all DB logic (using psycopg2) for authorized_bot_users table.
    """

    def __init__(self, config):
        """
        Inits repository with configuration (DB conn params).

        Parameters:
        - config: object - attributes: pg_host, pg_port, pg_user, pg_password, pg_database

        Returns:
        - NotificationUserRepository
        """
        self.config = config
        self._conn = None

    def _get_conn(self):
        """
        Gets or creates/reuses a single DB connection for this repo.

        Parameters:
        - None

        Returns:
        - psycopg2.Connection object
        """
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
        """
        Inserts or updates an authorized Telegram user.

        Parameters:
        - user_id: int - Telegram user ID
        - username: Optional[str] - Telegram username

        Returns:
        - None (side effect: record upserted in DB)
        """
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('''
                INSERT INTO authorized_bot_users (user_id, username, authorized_at) 
                VALUES (%s, %s, %s)
                ON CONFLICT (user_id) DO UPDATE SET username=EXCLUDED.username, authorized_at=EXCLUDED.authorized_at;
            ''', (user_id, username, datetime.datetime.utcnow()))
            conn.commit()

    def remove_user(self, user_id: int):
        """
        Removes user from authorized notifications.

        Parameters:
        - user_id: int - Telegram user ID

        Returns:
        - None (side effect: record deleted)
        """
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('DELETE FROM authorized_bot_users WHERE user_id=%s', (user_id,))
            conn.commit()

    def is_authorized(self, user_id: int) -> bool:
        """
        Checks if user is currently authorized (exists).

        Parameters:
        - user_id: int

        Returns:
        - bool: True if present, else False
        """
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('SELECT 1 FROM authorized_bot_users WHERE user_id=%s LIMIT 1', (user_id,))
            return cur.fetchone() is not None

    def get_all_authorized_user_ids(self) -> List[int]:
        """
        Returns a list of all currently authorized user IDs.

        Parameters:
        - None

        Returns:
        - List[int]: all Telegram user IDs in table
        """
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute('SELECT user_id FROM authorized_bot_users')
            return [row[0] for row in cur.fetchall()]

    def close(self):
        """
        Safely closes the DB connection if present (idempotent).

        Parameters:
        - None

        Returns:
        - None
        """
        if self._conn:
            self._conn.close()
            self._conn = None
