import hashlib
import hmac
import os
import re
import secrets
from contextlib import contextmanager
from threading import BoundedSemaphore

import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/auth", tags=["Autenticación"])
bearer = HTTPBearer(auto_error=False)
USER_COLUMNS = "id, username, full_name, email, phone_number, role, plan, currency, country_code"
PASSWORD_WORKERS = BoundedSemaphore(2)
DUMMY_SALT = bytes(16)


class Registration(BaseModel):
    full_name: str = Field(min_length=1, max_length=150)
    email: str = Field(min_length=3, max_length=255)
    phone_number: str = Field(default="", max_length=30)
    password: str = Field(min_length=12, max_length=128)
    currency: str = Field(default="BOB", pattern=r"^(BOB|USD|EUR|PEN|ARS)$")


class Login(BaseModel):
    identifier: str = Field(min_length=1, max_length=255)
    password: str = Field(min_length=1, max_length=128)


class PasswordChange(BaseModel):
    current_password: str = Field(min_length=1, max_length=128)
    new_password: str = Field(min_length=12, max_length=128)


@contextmanager
def database_cursor():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise HTTPException(503, "La autenticación está temporalmente fuera de servicio.")
    try:
        connection = psycopg2.connect(database_url, connect_timeout=5)
    except psycopg2.OperationalError:
        raise HTTPException(503, "La autenticación está temporalmente fuera de servicio.") from None
    try:
        with connection, connection.cursor(cursor_factory=RealDictCursor) as cursor:
            yield cursor
    finally:
        connection.close()


def hash_password(password: str, salt: bytes) -> str:
    if not PASSWORD_WORKERS.acquire(blocking=False):
        raise HTTPException(429, "Hay varias solicitudes de acceso. Intenta de nuevo.")
    try:
        digest = hashlib.scrypt(
            password.encode(), salt=salt, n=2**17, r=8, p=1, maxmem=192 * 1024**2,
        )
    finally:
        PASSWORD_WORKERS.release()
    return f"scrypt${salt.hex()}${digest.hex()}"


def new_password_hash(password: str) -> str:
    return hash_password(password, secrets.token_bytes(16))


def verify_password(password: str, stored: str | None) -> bool:
    if not stored:
        hash_password(password, DUMMY_SALT)
        return False
    algorithm, salt, _ = stored.split("$", 2)
    return algorithm == "scrypt" and hmac.compare_digest(hash_password(password, bytes.fromhex(salt)), stored)


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def open_session(cursor, user):
    cursor.execute("DELETE FROM public.auth_sessions WHERE user_id = %s AND expires_at <= now()", (user["id"],))
    token = secrets.token_urlsafe(32)
    cursor.execute(
        "INSERT INTO public.auth_sessions VALUES (%s, %s, now() + interval '12 hours')",
        (token_hash(token), user["id"]),
    )
    return {"token": token, "user": {key: user[key] for key in USER_COLUMNS.split(", ")}}


def require_token(credentials: HTTPAuthorizationCredentials | None = Depends(bearer)) -> str:
    if not credentials or len(credentials.credentials) != 43:
        raise HTTPException(401, "Inicia sesión nuevamente.")
    return token_hash(credentials.credentials)


@router.post("/register", status_code=201)
def register(request: Registration):
    email = request.email.strip().lower()
    full_name = request.full_name.strip()
    if not full_name or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        raise HTTPException(422, "Ingresa un nombre y un correo válidos.")
    username_prefix = re.sub(r"[^a-z0-9]", "", email.split("@", 1)[0])[:30] or "usuario"
    username = f"{username_prefix}-{secrets.token_hex(6)}"
    try:
        with database_cursor() as cursor:
            cursor.execute(
                f"""INSERT INTO public.users (username, full_name, email, phone_number, password_hash, currency)
                    VALUES (%s, %s, %s, %s, %s, %s) RETURNING {USER_COLUMNS}""",
                (username, full_name, email, request.phone_number.strip(), new_password_hash(request.password), request.currency),
            )
            return open_session(cursor, cursor.fetchone())
    except psycopg2.errors.UniqueViolation:
        raise HTTPException(409, "No se pudo registrar esa cuenta.") from None


@router.post("/login")
def login(request: Login):
    with database_cursor() as cursor:
        cursor.execute(
            f"SELECT {USER_COLUMNS}, password_hash FROM public.users WHERE email = %s OR username = %s",
            (request.identifier.strip().lower(),) * 2,
        )
        user = cursor.fetchone()
        if not verify_password(request.password, user["password_hash"] if user else None):
            raise HTTPException(401, "El usuario o la contraseña son incorrectos.")
        return open_session(cursor, user)


@router.post("/logout", status_code=204)
def logout(session: str = Depends(require_token)):
    with database_cursor() as cursor:
        cursor.execute("DELETE FROM public.auth_sessions WHERE token_hash = %s", (session,))


@router.post("/password", status_code=204)
def change_password(request: PasswordChange, session: str = Depends(require_token)):
    with database_cursor() as cursor:
        cursor.execute(
            """SELECT u.id, u.password_hash FROM public.auth_sessions s
               JOIN public.users u ON u.id = s.user_id
               WHERE s.token_hash = %s AND s.expires_at > now() FOR UPDATE OF u""",
            (session,),
        )
        user = cursor.fetchone()
        if not user or not verify_password(request.current_password, user["password_hash"]):
            raise HTTPException(401, "Sesión vencida o contraseña actual incorrecta.")
        cursor.execute(
            "UPDATE public.users SET password_hash = %s, updated_at = now() WHERE id = %s",
            (new_password_hash(request.new_password), user["id"]),
        )
        cursor.execute("DELETE FROM public.auth_sessions WHERE user_id = %s AND token_hash <> %s", (user["id"], session))
