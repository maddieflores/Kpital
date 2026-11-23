"""
Servicio de Oportunidades Comerciales y Tendencias Estacionales.
Indica al usuario qué productos tienen mayor demanda en el país según el mes y la época del año.
"""

from datetime import datetime
from typing import Dict, Any, List
from ai_service.prompts.country_contexts import get_country_context

class SeasonalTrendsService:

    @staticmethod
    def get_current_opportunities(country_code: str = "BO") -> Dict[str, Any]:
        """
        Devuelve las mejores oportunidades de negocio y productos recomendados
        para el mes actual en el país seleccionado.
        """
        current_month = datetime.now().month
        country = get_country_context(country_code)
        
        # Mapeo de recomendaciones por mes
        month_names = [
            "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
        ]
        
        # Determinación de temporada actual
        if current_month in [1, 2]:
            season_key = "1-2"
        elif current_month in [3, 4]:
            season_key = "3-4"
        elif current_month == 5:
            season_key = "5"
        elif current_month in [6, 7]:
            season_key = "6-7"
        elif current_month in [8, 9]:
            season_key = "8-9"
        elif current_month in [10, 11]:
            season_key = "10-11"
        else:
            season_key = "12"

        season_description = country["seasonal_calendar"].get(
            season_key, "Temporada regular de comercio."
        )

        return {
            "country": country["country_name"],
            "current_month": month_names[current_month],
            "seasonal_focus": season_description,
            "evergreen_products": country["evergreen_products"],
            "ai_actionable_tip": (
                f"Si planeas invertir en {month_names[current_month]}, combina un 70% de capital "
                f"en productos de alta rotación constante y un 30% en mercadería de temporada ({season_description}) "
                f"para maximizar liquidez y no quedarte con mercadería estancada."
            )
        }
