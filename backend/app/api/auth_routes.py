from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/api/auth", tags=["Autenticación y Recuperación"])
notifications_router = APIRouter(prefix="/api/notifications", tags=["Notificaciones"])

# Schemas
class SendCodeRequest(BaseModel):
    channel: str = Field(..., example="email", description="'email' o 'whatsapp'")
    target: str = Field(..., example="addelynie@gmail.com", description="Email o teléfono")
    user_name: Optional[str] = Field(default="Madeline", example="Madeline Flores")

class VerifyCodeRequest(BaseModel):
    target: str = Field(..., example="addelynie@gmail.com")
    code: str = Field(..., example="123456")

class RegisterTokenRequest(BaseModel):
    user_id: str = Field(..., example="maddie")
    fcm_token: str = Field(..., example="fcm_token_sample_12345")

# Memoria de tokens FCM registrados
_FCM_TOKENS: Dict[str, str] = {}

@router.post("/send-recovery-code")
def send_recovery_code(req: SendCodeRequest):
    """
    Envía un código de recuperación vía Email (Resend/SMTP) o WhatsApp Cloud API.
    """
    code = NotificationService.generate_code(target=req.target, user_name=req.user_name or "Madeline")
    
    if req.channel.lower() == "email":
        result = NotificationService.send_email_code(to_email=req.target, code=code, user_name=req.user_name or "Madeline")
    elif req.channel.lower() in ["whatsapp", "phone", "sms"]:
        result = NotificationService.send_whatsapp_code(phone_number=req.target, code=code, user_name=req.user_name or "Madeline")
    else:
        raise HTTPException(status_code=400, detail="Canal no soportado. Usa 'email' o 'whatsapp'.")
        
    return {
        "status": "success",
        "channel": req.channel,
        "target": req.target,
        "detail": result
    }

@router.post("/verify-recovery-code")
def verify_recovery_code(req: VerifyCodeRequest):
    """
    Valida si el código de 6 dígitos ingresado por el usuario es correcto y no ha expirado.
    """
    is_valid = NotificationService.verify_code(target=req.target, input_code=req.code)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Código de verificación incorrecto o expirado.")
        
    return {
        "status": "success",
        "verified": True,
        "message": "Identidad confirmada exitosamente."
    }

@notifications_router.post("/register-fcm-token")
def register_fcm_token(req: RegisterTokenRequest):
    """
    Registra el token de Firebase Cloud Messaging del dispositivo del usuario.
    """
    _FCM_TOKENS[req.user_id] = req.fcm_token
    return {
        "status": "success",
        "message": f"Token FCM registrado para el usuario {req.user_id}"
    }

@notifications_router.get("/tokens")
def get_registered_tokens():
    """Lista los dispositivos registrados para push notifications"""
    return {
        "total": len(_FCM_TOKENS),
        "users": list(_FCM_TOKENS.keys())
    }
