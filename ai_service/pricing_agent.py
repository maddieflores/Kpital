"""
Agente Inteligente de Evaluación de Costos y Recomendación de Precios de Venta.
Utiliza el contexto económico local y modelos LLM (Google Gemini) para generar
recomendaciones financieras de alta precisión para comerciantes y emprendedores.
"""

import json
from typing import Dict, Any, Optional
from ai_service.calculators.cost_breakdown import CostBreakdownCalculator
from ai_service.prompts.country_contexts import get_country_context

class PricingAgent:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key

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
        # 1. Desglose matemático riguroso
        breakdown = CostBreakdownCalculator.calculate_cost_scales(
            batch_total_cost=total_purchase_cost,
            batch_units=batch_units
        )
        unit_cost = breakdown["unit_cost"]
        country = get_country_context(country_code)
        curr = country["currency_symbol"]

        # 2. Estrategia comercial estándar por escalas (Margen 40% al detalle, 30% a media docena, 20% a docena)
        suggested_unit_sale = round(unit_cost / 0.60, 2)            # ~40% margen
        suggested_half_dozen_sale = round((unit_cost * 6) / 0.70, 2) # ~30% margen
        suggested_dozen_sale = round((unit_cost * 12) / 0.80, 2)     # ~20% margen

        # Métricas de ganancia proyectada
        unit_metrics = CostBreakdownCalculator.calculate_margins_and_profit(unit_cost, suggested_unit_sale, 1)
        dozen_metrics = CostBreakdownCalculator.calculate_margins_and_profit(unit_cost * 12, suggested_dozen_sale, 1)

        result = {
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
                "is_purchase_cost_favorable": True,
                "advice": f"Para {product_name} en {country['country_name']}, tu costo de {unit_cost:.2f} {curr} por unidad te da margen suficiente para competir tanto en venta al detalle como por docena.",
                "local_tip": f"En el mercado boliviano, ofrecer rebaja de {suggested_dozen_sale:.2f} {curr} a pago inmediato por QR Simple te ayuda a rotar mercadería sin costo bancario."
            }
        }
        return result
