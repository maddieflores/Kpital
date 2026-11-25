from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from .auth_routes import database_cursor, require_token

router = APIRouter(prefix="/api", tags=["Finanzas y Cuentas"])


def get_current_user_id(session: str = Depends(require_token)) -> str:
    with database_cursor() as cursor:
        cursor.execute(
            """SELECT user_id FROM public.auth_sessions 
               WHERE token_hash = %s AND expires_at > now()""",
            (session,),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(401, "Sesión vencida o inválida. Inicia sesión nuevamente.")
        return str(row["user_id"])


# Modelos Pydantic
class AccountPayload(BaseModel):
    id: str
    name: str
    type: str = "cash"
    currency: str = "BOB"
    balance: float = 0.0
    isSavingsVault: bool = Field(default=False, alias="is_savings_vault")
    targetAmount: Optional[float] = Field(default=None, alias="target_amount")
    colorHex: str = Field(default="#3366D6", alias="color_hex")
    iconName: Optional[str] = Field(default=None, alias="icon_name")
    createdAt: Optional[str] = Field(default=None, alias="created_at")

    model_config = ConfigDict(populate_by_name=True)


class AccountSyncPayload(BaseModel):
    accounts: List[AccountPayload]


class TransactionPayload(BaseModel):
    id: str
    accountId: str = Field(alias="account_id")
    accountName: str = Field(default="Cuenta", alias="account_name")
    destinationAccountId: Optional[str] = Field(default=None, alias="destination_account_id")
    destinationAccountName: Optional[str] = Field(default=None, alias="destination_account_name")
    type: str = "income"
    amount: float = Field(gt=0, lt=1_000_000_000_000, allow_inf_nan=False)
    currency: str = "BOB"
    contactName: Optional[str] = Field(default=None, alias="contact_name")
    description: Optional[str] = None
    category: Optional[str] = None
    receiptImagePath: Optional[str] = Field(default=None, alias="receipt_image_url")
    transactionDate: Optional[str] = Field(default=None, alias="transaction_date")
    isEssential: bool = Field(default=True, alias="is_essential")
    createdAt: Optional[str] = Field(default=None, alias="created_at")

    model_config = ConfigDict(populate_by_name=True)


class TransactionSyncPayload(BaseModel):
    transactions: List[TransactionPayload]


def format_account_row(row: dict) -> dict:
    return {
        "id": str(row["id"]),
        "name": row["name"],
        "type": row["type"],
        "currency": row.get("currency") or "BOB",
        "balance": float(row.get("balance") or 0.0),
        "isSavingsVault": bool(row.get("is_savings_vault", False)),
        "targetAmount": float(row["target_amount"]) if row.get("target_amount") is not None else None,
        "colorHex": row.get("color_hex") or "#3366D6",
        "createdAt": row["created_at"].isoformat() if row.get("created_at") else datetime.now().isoformat(),
    }


def format_transaction_row(row: dict) -> dict:
    return {
        "id": str(row["id"]),
        "accountId": str(row["account_id"]),
        "accountName": row.get("account_name") or "Cuenta",
        "destinationAccountId": str(row["destination_account_id"]) if row.get("destination_account_id") else None,
        "destinationAccountName": row.get("destination_account_name"),
        "type": row["type"],
        "amount": float(row.get("amount") or 0.0),
        "currency": row.get("currency") or "BOB",
        "contactName": row.get("contact_name"),
        "description": row.get("description"),
        "category": row.get("category"),
        "isEssential": row.get("is_essential", True),
        "receiptImagePath": row.get("receipt_image_url"),
        "transactionDate": row["transaction_date"].isoformat() if row.get("transaction_date") else datetime.now().isoformat(),
        "createdAt": row["created_at"].isoformat() if row.get("created_at") else datetime.now().isoformat(),
    }


# =========================================================================
# RUTAS DE CUENTAS (/api/accounts)
# =========================================================================

@router.get("/accounts")
def list_accounts(user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        cursor.execute(
            """SELECT id, name, type, currency, balance, is_savings_vault, target_amount, color_hex, created_at
               FROM public.accounts
               WHERE user_id = %s
               ORDER BY created_at ASC""",
            (user_id,),
        )
        rows = cursor.fetchall()
        return [format_account_row(r) for r in rows]


@router.post("/accounts")
def create_or_update_account(payload: AccountPayload, user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        cursor.execute(
            """INSERT INTO public.accounts (id, user_id, name, type, currency, balance, is_savings_vault, target_amount, color_hex)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
               ON CONFLICT (id) DO UPDATE SET
                   name = EXCLUDED.name,
                   type = EXCLUDED.type,
                   currency = EXCLUDED.currency,
                   balance = EXCLUDED.balance,
                   is_savings_vault = EXCLUDED.is_savings_vault,
                   target_amount = EXCLUDED.target_amount,
                   color_hex = EXCLUDED.color_hex
               WHERE accounts.user_id = EXCLUDED.user_id
               RETURNING *""",
            (
                payload.id,
                user_id,
                payload.name,
                payload.type,
                payload.currency,
                payload.balance,
                payload.isSavingsVault,
                payload.targetAmount,
                payload.colorHex,
            ),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(409, "No se pudo guardar esa cuenta.")
        return format_account_row(row)


@router.delete("/accounts/{account_id}", status_code=204)
def delete_account(account_id: str, user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        cursor.execute(
            "DELETE FROM public.accounts WHERE id = %s AND user_id = %s",
            (account_id, user_id),
        )


@router.post("/accounts/sync")
def sync_accounts(payload: AccountSyncPayload, user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        # Upsert cada cuenta local que mande el cliente
        for acc in payload.accounts:
            cursor.execute(
                """INSERT INTO public.accounts (id, user_id, name, type, currency, balance, is_savings_vault, target_amount, color_hex)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                   ON CONFLICT (id) DO NOTHING""",
                (
                    acc.id,
                    user_id,
                    acc.name,
                    acc.type,
                    acc.currency,
                    acc.balance,
                    acc.isSavingsVault,
                    acc.targetAmount,
                    acc.colorHex,
                ),
            )

        # Retornar el estado consolidado de todas las cuentas del usuario
        cursor.execute(
            """SELECT id, name, type, currency, balance, is_savings_vault, target_amount, color_hex, created_at
               FROM public.accounts
               WHERE user_id = %s
               ORDER BY created_at ASC""",
            (user_id,),
        )
        rows = cursor.fetchall()
        return [format_account_row(r) for r in rows]


# =========================================================================
# RUTAS DE TRANSACCIONES (/api/transactions)
# =========================================================================

@router.get("/transactions")
def list_transactions(user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        cursor.execute(
            """SELECT id, account_id, account_name, destination_account_id, destination_account_name,
                      type, amount, currency, contact_name, description, category,
                      receipt_image_url, is_essential, transaction_date, created_at
               FROM public.transactions
               WHERE user_id = %s AND deleted_at IS NULL
               ORDER BY transaction_date DESC""",
            (user_id,),
        )
        rows = cursor.fetchall()
        return [format_transaction_row(r) for r in rows]


def insert_transaction(cursor, payload: TransactionPayload, user_id: str):
    try:
        tx_date = datetime.fromisoformat(payload.transactionDate) if payload.transactionDate else datetime.now()
    except ValueError:
        raise HTTPException(422, "La fecha del movimiento no es válida.") from None
    cursor.execute(
        """INSERT INTO public.transactions (
               id, user_id, account_id, account_name, destination_account_id,
               destination_account_name, type, amount, currency, contact_name,
               description, category, receipt_image_url, transaction_date, is_essential
           )
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
           ON CONFLICT (id) DO NOTHING RETURNING *""",
        (payload.id, user_id, payload.accountId, payload.accountName,
         payload.destinationAccountId, payload.destinationAccountName, payload.type,
         payload.amount, payload.currency, payload.contactName, payload.description,
         payload.category, payload.receiptImagePath, tx_date, payload.isEssential),
    )
    return cursor.fetchone()


def apply_balance_changes(cursor, user_id: str, row: dict, *, reverse: bool = False):
    kind = row["type"]
    origin = row["account_id"]
    destination = row["destination_account_id"]
    amount = row["amount"]
    if kind == "income":
        changes = {origin: amount}
    elif kind == "expense":
        changes = {origin: -amount}
    elif kind == "transfer" and destination and destination != origin:
        changes = {origin: -amount, destination: amount}
    else:
        raise HTTPException(422, "El tipo o destino del movimiento no es válido.")

    for account_id, delta in sorted(changes.items()):
        cursor.execute(
            """UPDATE public.accounts SET balance = COALESCE(balance, 0) + %s
               WHERE id = %s AND user_id = %s""",
            (-delta if reverse else delta, account_id, user_id),
        )
        if not cursor.rowcount and not reverse:
            raise HTTPException(409, "La cuenta del movimiento no está disponible.")


@router.post("/transactions")
def create_transaction(payload: TransactionPayload, user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        row = insert_transaction(cursor, payload, user_id)
        if row:
            apply_balance_changes(cursor, user_id, row)
            return format_transaction_row(row)
        cursor.execute(
            "SELECT * FROM public.transactions WHERE id = %s AND user_id = %s AND deleted_at IS NULL",
            (payload.id, user_id),
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(409, "No se pudo guardar ese movimiento.")
        return format_transaction_row(row)


@router.delete("/transactions/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: str, user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        cursor.execute(
            """UPDATE public.transactions SET deleted_at = now()
               WHERE id = %s AND user_id = %s AND deleted_at IS NULL RETURNING *""",
            (transaction_id, user_id),
        )
        row = cursor.fetchone()
        if row:
            apply_balance_changes(cursor, user_id, row, reverse=True)


@router.post("/transactions/sync")
def sync_transactions(payload: TransactionSyncPayload, user_id: str = Depends(get_current_user_id)):
    with database_cursor() as cursor:
        # These movements are historical. The account import already includes their balances.
        for tx in payload.transactions:
            insert_transaction(cursor, tx, user_id)

        cursor.execute(
            """SELECT id, account_id, account_name, destination_account_id, destination_account_name,
                      type, amount, currency, contact_name, description, category,
                      receipt_image_url, is_essential, transaction_date, created_at
               FROM public.transactions
               WHERE user_id = %s AND deleted_at IS NULL
               ORDER BY transaction_date DESC""",
            (user_id,),
        )
        rows = cursor.fetchall()
        return [format_transaction_row(r) for r in rows]
