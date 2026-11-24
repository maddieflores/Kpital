"""
Agente Inteligente de Evaluación de Costos y Recomendación de Precios de Venta.
Utiliza Google Gemini (SDK google-genai) con contexto macroeconómico y comercial de Bolivia y Argentina.
Cuenta con sistema de respaldo automático (Fallback Heurístico) si no hay API Key o conexión.
"""

import os
import json
import logging
from pathlib import Path
from typing import Dict, Any, Optional
from dotenv import load_dotenv
from ai_service.calculators.cost_breakdown import CostBreakdownCalculator
from ai_service.prompts.country_contexts import get_country_context

# Cargar variables de entorno desde .env
load_dotenv(Path(__file__).resolve().parents[1] / "backend" / ".env")
load_dotenv()

logger = logging.getLogger("PricingAgent")

class PricingAgent:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        self._gemini_client = None

        if self.api_key:
            try:
                from google import genai
                self._gemini_client = genai.Client(
                    api_key=self.api_key,
                    http_options={"timeout": 15000},
                )
                logger.info("Cliente de Google Gemini inicializado correctamente.")
            except Exception as e:
                logger.warning("No se pudo inicializar Gemini (%s).", type(e).__name__)

    def analyze_pricing(
        self,
        product_name: str,
        total_purchase_cost: float,
        batch_units: int,
        country_code: str = "BO",
        extra_notes: str = ""
    ) -> Dict[str, Any]:
        """
        Analiza el costo de adquisición de un lote y genera una recomendación
        estructurada de precios para venta por Unidad, Media Docena y Docena.
        """
        # 1. Desglose matemático riguroso base
        breakdown = CostBreakdownCalculator.calculate_cost_scales(
            batch_total_cost=total_purchase_cost,
            batch_units=batch_units
        )
        unit_cost = breakdown["unit_cost"]
        country = get_country_context(country_code)
        curr = country["currency_symbol"]

        # Margen estándar: 40% detalle, 30% media docena, 20% docena
        suggested_unit_sale = round(unit_cost / 0.60, 2)
        suggested_half_dozen_sale = round((unit_cost * 6) / 0.70, 2)
        suggested_dozen_sale = round((unit_cost * 12) / 0.80, 2)

        unit_metrics = CostBreakdownCalculator.calculate_margins_and_profit(unit_cost, suggested_unit_sale, 1)
        dozen_metrics = CostBreakdownCalculator.calculate_margins_and_profit(unit_cost * 12, suggested_dozen_sale, 1)

        # 2. Veredicto por defecto (motor heurístico de respaldo)
        is_favorable = unit_cost > 0
        advice = (
            f"Para {product_name} en {country['country_name']}, tu costo de {unit_cost:.2f} {curr} por unidad "
            f"te deja un margen comercial óptimo para competir tanto al detalle como en ventas por docena."
        )
        local_tip = (
            f"En mercados bolivianos, ofrecer el precio de docena a {suggested_dozen_sale:.2f} {curr} "
            f"con cobro inmediato por QR Simple de Banco Unión o BCP evita pérdidas por cambio o billetes falsos."
            if country_code.upper() == "BO"
            else "En Argentina, revisa tus precios de venta cada 15 a 30 días para cubrir el costo de reposición del próximo lote."
        )

        # 3. Consulta a Google Gemini si hay cliente activo
        verdict_source = "fallback"
        if self._gemini_client:
            try:
                gemini_data = self._consult_gemini(
                    product_name=product_name,
                    total_purchase_cost=total_purchase_cost,
                    batch_units=batch_units,
                    unit_cost=unit_cost,
                    country_name=country["country_name"],
                    currency_symbol=curr,
                    extra_notes=extra_notes,
                    market_context=country["market_characteristics"],
                )
                if gemini_data:
                    advice = gemini_data.get("advice", advice)
                    local_tip = gemini_data.get("local_tip", local_tip)
                    is_favorable = gemini_data.get("is_purchase_cost_favorable", is_favorable)
                    verdict_source = "gemini"
                    logger.info("Veredicto generado exitosamente por Google Gemini.")
            except Exception as e:
                logger.warning("Consulta Gemini fallida (%s). Usando respaldo.", type(e).__name__)

        return {
            "product_name": product_name,
            "country": country["country_name"],
            "currency": country["currency_code"],
            "cost_breakdown": {
                "batch_total_cost": f"{total_purchase_cost:.2f} {curr}",
                "batch_units": batch_units,
                "unit_cost": f"{unit_cost:.2f} {curr}",
                "half_dozen_cost": f"{breakdown['half_dozen_cost']:.2f} {curr}",
                "dozen_cost": f"{breakdown['dozen_cost']:.2f} {curr}",
            },
            "suggested_pricing": {
                "unit": {
                    "price": f"{suggested_unit_sale:.2f} {curr}",
                    "profit": f"{unit_metrics['profit_per_unit']:.2f} {curr}",
                    "margin_percent": f"{unit_metrics['margin_percent']}%",
                    "strategy": "Venta al detalle al consumidor final para maximizar ganancia."
                },
                "half_dozen": {
                    "price": f"{suggested_half_dozen_sale:.2f} {curr}",
                    "profit": f"{(suggested_half_dozen_sale - breakdown['half_dozen_cost']):.2f} {curr}",
                    "strategy": "Incentivo intermedio con descuento para compras familiares o revendedores pequeños."
                },
                "dozen": {
                    "price": f"{suggested_dozen_sale:.2f} {curr}",
                    "profit": f"{dozen_metrics['profit_per_unit']:.2f} {curr}",
                    "margin_percent": f"{dozen_metrics['margin_percent']}%",
                    "strategy": "Venta mayorista rápida para recuperar el capital invertido en pocos días."
                }
            },
            "ai_verdict": {
                "source": verdict_source,
                "is_purchase_cost_favorable": is_favorable,
                "advice": advice,
                "local_tip": local_tip
            }
        }

    def _consult_gemini(
        self,
        product_name: str,
        total_purchase_cost: float,
        batch_units: int,
        unit_cost: float,
        country_name: str,
        currency_symbol: str,
        extra_notes: str,
        market_context: str,
    ) -> Optional[Dict[str, Any]]:
        """Llama a Gemini usando el SDK google-genai para obtener el veredicto comercial con cascada de modelos."""
        prompt = f"""
Eres el asesor experto de comercio minorista y mayorista de la aplicación Kpital en {country_name}.
Un comerciante acaba de comprar o está cotizando el siguiente lote:
- Producto: {product_name}
- Costo total pagado: {total_purchase_cost} {currency_symbol}
- Unidades contenidas: {batch_units} unidades
- Costo unitario resultante: {unit_cost:.2f} {currency_symbol}
- Notas adicionales: {extra_notes or "Ninguna"}

Contexto del mercado:
{market_context}

Debes responder ÚNICAMENTE un objeto JSON válido con la siguiente estructura:
{{
  "is_purchase_cost_favorable": true o false (evalúa si el costo unitario de {unit_cost:.2f} {currency_symbol} es favorable para competir en ferias y tiendas),
  "advice": "Consejo comercial específico para vender {product_name} en {country_name}, considerando rotación y márgenes (máximo 2 a 3 oraciones concisas).",
  "local_tip": "Un tip práctico para ferias locales (ej. La Cancha, 16 de Julio, Los Pozos, Once), métodos de cobro como QR Simple o estrategias de regateo/volumen (máximo 2 oraciones)."
}}
No incluyas texto fuera del bloque JSON.
"""
        candidate_models = ("gemini-3.5-flash-lite", "gemini-3.8-flash", "gemini-3.6-flash")
        last_error = None

        for model_name in candidate_models:
            try:
                response = self._gemini_client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config={"response_mime_type": "application/json"},
                )
                text = response.text.strip()
                if text.startswith("```json"):
                    text = text[7:]
                if text.startswith("```"):
                    text = text[3:]
                if text.endswith("```"):
                    text = text[:-3]
                text = text.strip()
                verdict = json.loads(text)
                if (
                    not isinstance(verdict, dict)
                    or not isinstance(verdict.get("is_purchase_cost_favorable"), bool)
                    or not all(
                        isinstance(verdict.get(field), str) and verdict[field].strip()
                        for field in ("advice", "local_tip")
                    )
                ):
                    raise ValueError("Veredicto Gemini incompleto")
                return verdict
            except Exception as e:
                last_error = e
                logger.warning("Falló el modelo %s (%s).", model_name, type(e).__name__)

        if last_error:
            raise last_error
        return None
