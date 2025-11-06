# SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
#
# SPDX-License-Identifier: MIT

"""
Authorization manager for notification-bot Telegram users.
Provides Authorization/Deauthorization/checks for use in gRPC, bot commands.
"""
import threading
import time
import jwt
import base64
import os
from urllib.parse import urlencode
from src.clients import NotificationUserRepository
from typing import Optional
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

class UserAuthManager:
    """
    Abstraction for Telegram user authorization. As of 2025-11-07, registration for the bot is strictly based on user_id (int/str); username is ignored for all WebApp and standard flows.
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

    def authorize(self, user_id: int):
        """
        Adds user to authorized set by user_id only. Username is deprecated and ignored (2025-11-07).

        Parameters:
        - user_id: int

        Returns:
        - None
        """
        self.user_repo.add_user(user_id)

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

def generate_login_token(user_id: str, secret: str, expiry_secs: int = 180) -> str:
    """
    Generates a signed JWT token for WebApp login/session.
    Token contains user id (uid, as string) and expiry (exp, UNIX epoch seconds).
    Only valid when signed with configured WEBAPP_TOKEN_SECRET.

    Parameters:
    - user_id: str - unique identifier of user/session for this token
    - secret: str - secret key for signing (should come from config)
    - expiry_secs: int - seconds until expiry (default: 180)

    Returns:
    - str: signed JWT

    Example:
    - token = generate_login_token("12345", secret)
    """
    now = int(time.time())
    payload = {'uid': str(user_id), 'exp': now + expiry_secs}
    return jwt.encode(payload, secret, algorithm="HS256")

def validate_login_token(token: str, user_id: str, secret: str) -> bool:
    """
    Validates a JWT WebApp-login token for authenticity and recency.

    Parameters:
    - token: str - JWT to validate
    - user_id: str - expected user id (should match token payload)
    - secret: str - secret key for signature (must match creation)

    Returns:
    - bool: True if valid and uid/exp checks pass, else False

    Example:
    - validate_login_token(token, "12345", secret)
    """
    try:
        payload = jwt.decode(token, secret, algorithms=["HS256"])
        uid_match = payload.get("uid") == str(user_id)
        exp_valid = payload.get("exp", 0) > int(time.time())
        return uid_match and exp_valid

    except Exception as e:
        return False

def decrypt_uid_for_webapp(euid: str, secret: str) -> str:
    """
    Decrypts encrypted user_id (euid, as produced by encrypt_uid_for_webapp) using AES-256-GCM.

    Parameters:
    - euid: str - base64url-encoded string (iv + ciphertext + tag, 12 + N + 16 bytes)
    - secret: str - base64 string (WEBAPP_TOKEN_SECRET) for decryption key

    Returns:
    - str: decrypted user_id

    Raises:
    - ValueError: on invalid data or decryption failure

    Example:
    - decrypt_uid_for_webapp(euid, secret)
    """
    try:
        data = base64.urlsafe_b64decode(euid.encode("utf-8"))
        iv, ct_tag = data[:12], data[12:]

        if len(ct_tag) < 16:
            raise ValueError("euid payload too short")

        ct, tag = ct_tag[:-16], ct_tag[-16:]
        key = base64.b64decode(secret)[:32]

        cipher = Cipher(
            algorithms.AES(key),
            modes.GCM(iv, tag),
            backend=default_backend()
        )

        decryptor = cipher.decryptor()
        user_id_bytes = decryptor.update(ct) + decryptor.finalize()
        return user_id_bytes.decode("utf-8")

    except Exception as ex:
        raise ValueError("Failed to decrypt user_id from euid: %s" % ex)

def encrypt_uid_for_webapp(user_id: str, secret: str) -> str:
    """
    Encrypts a user_id (string) for secure WebApp flows using AES-256-GCM.

    Parameters:
    - user_id: str - Telegram user ID or similar (string or int convertible to str)
    - secret: str - base64 string (WEBAPP_TOKEN_SECRET) for encryption key

    Returns:
    - str: Encrypted, base64url-encoded euid (iv + ciphertext + tag)

    Example:
    - encrypt_uid_for_webapp("12345", secret)
    """
    raw = str(user_id).encode('utf-8')
    key = base64.b64decode(secret)[:32]
    iv = os.urandom(12)
    cipher = Cipher(algorithms.AES(key), modes.GCM(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    ct = encryptor.update(raw) + encryptor.finalize()
    tag = encryptor.tag
    euid = iv + ct + tag
    return base64.urlsafe_b64encode(euid).decode('utf-8')

def get_webapp_url(domain: str, user_id: str, token: str, secret: str) -> str:
    """
    Generates a secure, user-specific WebApp URL for Telegram authorization.
    All user_id transmission occurs strictly as encrypted euid (see PLAN.md/security rationale).

    Parameters:
    - domain: str - full domain name (no protocol)
    - user_id: str - user/session ID to encrypt (never exposed in URL)
    - token: str - secure JWT/nonce for WebApp session
    - secret: str - WEBAPP_TOKEN_SECRET from config (base64 string)

    Returns:
    - str: WebApp URL with only euid and token as params

    Raises:
    - RuntimeError: if encryption fails or domain unset

    Example:
    - get_webapp_url("example.com", "12345", token, secret)
    """
    if not domain:
        raise RuntimeError("DOMAIN must be set for WebApp URL generation.")
    euid = encrypt_uid_for_webapp(user_id, secret)
    params = urlencode({"euid": euid, "token": token})
    return f"https://{domain}/auth/webapp?{params}"

# Global singleton
user_auth_manager = None
