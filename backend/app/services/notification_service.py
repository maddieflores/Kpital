"""
Servicio de Notificaciones y Mensajería para Kpital
Soporta:
1. Email vía Resend API (Gratuito 3,000 emails/mes) y fallback SMTP (Gmail)
2. WhatsApp vía Meta WhatsApp Cloud API (Gratuito 1,000 conversaciones/mes)
3. Gestión y expiración de códigos OTP de recuperación (10 minutos)
"""

import os
import random
import time
import smtplib
import requests
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any, Optional

# Almacén temporal de códigos OTP en memoria { "target": {"code": "...", "expires": float, "user": "..."} }
_OTP_CACHE: Dict[str, Dict[str, Any]] = {}

class NotificationService:
    # 1. Configuración de Email (Resend y SMTP)
    RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
    RESEND_FROM_EMAIL = os.getenv("RESEND_FROM_EMAIL", "Kpital <onboarding@resend.dev>")
    
    SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "465"))
    SMTP_USER = os.getenv("SMTP_USER", "")
    SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
    
    # 2. Configuración de WhatsApp Cloud API (Meta)
    WHATSAPP_TOKEN = os.getenv("WHATSAPP_CLOUD_API_TOKEN", "")
    WHATSAPP_PHONE_ID = os.getenv("WHATSAPP_PHONE_NUMBER_ID", "")
    
    @classmethod
    def generate_code(cls, target: str, user_name: str = "Madeline") -> str:
        """Genera un código de 6 dígitos con expiración de 10 minutos"""
        code = f"{random.randint(100000, 999999)}"
        _OTP_CACHE[target.lower()] = {
            "code": code,
            "expires": time.time() + 600, # 10 minutos
            "user_name": user_name
        }
        return code

    @classmethod
    def verify_code(cls, target: str, input_code: str) -> bool:
        """Verifica si el código es válido y no ha expirado"""
        key = target.lower()
        # Código comodín para desarrollo/pruebas offline
        if input_code.strip() == "123456":
            return True
            
        if key not in _OTP_CACHE:
            return False
            
        data = _OTP_CACHE[key]
        if time.time() > data["expires"]:
            del _OTP_CACHE[key]
            return False
            
        if data["code"] == input_code.strip():
            del _OTP_CACHE[key]
            return True
            
        return False

    @classmethod
    def send_email_code(cls, to_email: str, code: str, user_name: str = "Madeline") -> Dict[str, Any]:
        """Envía el código de recuperación vía Resend o SMTP de Gmail"""
        subject = f"Tu código de acceso Kpital: {code}"
        html_content = f"""
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 500px; margin: auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
            <div style="text-align: center; margin-bottom: 20px;">
                <h1 style="color: #8261B8; margin: 0; font-size: 28px; letter-spacing: -1px;">Kpital.</h1>
                <p style="color: #64748b; font-size: 14px; margin-top: 4px;">Tu capital, en calma</p>
            </div>
            
            <p style="color: #334155; font-size: 16px;">Hola <strong>{user_name}</strong>,</p>
            <p style="color: #475569; font-size: 14px; line-height: 1.5;">
                Has solicitado un código de verificación para acceder o recuperar tu cuenta en Kpital.
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
                <div style="display: inline-block; padding: 14px 32px; background: #8261B8; color: #ffffff; font-size: 32px; font-weight: bold; letter-spacing: 8px; border-radius: 12px;">
                    {code}
                </div>
                <p style="color: #94a3b8; font-size: 12px; margin-top: 8px;">Válido durante los próximos 10 minutos.</p>
            </div>
            
            <p style="color: #64748b; font-size: 13px;">Si no solicitaste este código, puedes ignorar este correo de forma segura.</p>
            
            <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
            <p style="color: #94a3b8; font-size: 11px; text-align: center;">Kpital App · Finanzas Inteligentes y Micro-negocios</p>
        </div>
        """

        # 1. Intentar con Resend API
        if cls.RESEND_API_KEY:
            try:
                res = requests.post(
                    "https://api.resend.com/emails",
                    headers={
                        "Authorization": f"Bearer {cls.RESEND_API_KEY}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "from": cls.RESEND_FROM_EMAIL,
                        "to": [to_email],
                        "subject": subject,
                        "html": html_content
                    },
                    timeout=5
                )
                if res.status_code in [200, 201]:
                    return {"status": "success", "provider": "resend", "data": res.json()}
                else:
                    print(f"[Resend Error] {res.text}")
            except Exception as e:
                print(f"[Resend Exception] {e}")

        # 2. Fallback con SMTP de Gmail
        if cls.SMTP_USER and cls.SMTP_PASSWORD:
            try:
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject
                msg["From"] = f"Kpital <{cls.SMTP_USER}>"
                msg["To"] = to_email
                msg.attach(MIMEText(html_content, "html"))

                if cls.SMTP_PORT == 465:
                    with smtplib.SMTP_SSL(cls.SMTP_HOST, cls.SMTP_PORT, timeout=5) as server:
                        server.login(cls.SMTP_USER, cls.SMTP_PASSWORD)
                        server.send_message(msg)
                else:
                    with smtplib.SMTP(cls.SMTP_HOST, cls.SMTP_PORT, timeout=5) as server:
                        server.starttls()
                        server.login(cls.SMTP_USER, cls.SMTP_PASSWORD)
                        server.send_message(msg)

                return {"status": "success", "provider": "smtp", "message": "Email enviado exitosamente vía SMTP"}
            except Exception as e:
                print(f"[SMTP Exception] {e}")

        # 3. Modo Simulado / Registro en consola (si aún no se han configurado llaves API)
        print(f"\n[KPITAL NOTIFICACIÓN EMAIL] Para: {to_email} | Código: {code}\n")
        return {
            "status": "simulated",
            "provider": "console",
            "message": f"Código generado: {code}. Configura RESEND_API_KEY o SMTP_USER en .env para entrega externa.",
            "code": code
        }

    @classmethod
    def send_whatsapp_code(cls, phone_number: str, code: str, user_name: str = "Madeline") -> Dict[str, Any]:
        """Envía el código vía WhatsApp Cloud API de Meta"""
        # Normalizar teléfono: quitar espacios, signos +, etc. Ej: 59169069393
        clean_phone = phone_number.replace("+", "").replace(" ", "").replace("-", "")
        if len(clean_phone) == 8 and (clean_phone.startswith("7") or clean_phone.startswith("6")):
            clean_phone = f"591{clean_phone}"

        message_text = (
            f"Hola {user_name} 👋\n\n"
            f"Tu código de verificación para Kpital es:\n\n"
            f"👉 *{code}*\n\n"
            f"Válido por 10 minutos. No compartas este código con nadie."
        )

        # 1. Intentar con Meta WhatsApp Cloud API
        if cls.WHATSAPP_TOKEN and cls.WHATSAPP_PHONE_ID:
            try:
                url = f"https://graph.facebook.com/v18.0/{cls.WHATSAPP_PHONE_ID}/messages"
                res = requests.post(
                    url,
                    headers={
                        "Authorization": f"Bearer {cls.WHATSAPP_TOKEN}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "messaging_product": "whatsapp",
                        "recipient_type": "individual",
                        "to": clean_phone,
                        "type": "text",
                        "text": {"preview_url": False, "body": message_text}
                    },
                    timeout=5
                )
                if res.status_code in [200, 201]:
                    return {"status": "success", "provider": "whatsapp_cloud_api", "data": res.json()}
                else:
                    print(f"[WhatsApp API Error] {res.text}")
            except Exception as e:
                print(f"[WhatsApp Exception] {e}")

        # 2. Modo Simulado / Registro en consola
        print(f"\n[KPITAL NOTIFICACIÓN WHATSAPP] Para: +{clean_phone} | Código: {code}\n")
        return {
            "status": "simulated",
            "provider": "console",
            "message": f"Código para +{clean_phone}: {code}. Configura WHATSAPP_CLOUD_API_TOKEN en .env para entrega automática.",
            "code": code,
            "wa_link": f"https://wa.me/{clean_phone}?text={requests.utils.quote(message_text)}"
        }
