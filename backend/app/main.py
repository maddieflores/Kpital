"""
Punto de entrada de la API Backend (FastAPI)
Conecta la base de datos, el recomendador de precios con IA y la gestión financiera.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from ai_service.pricing_agent import PricingAgent
from ai_service.seasonal_trends import SeasonalTrendsService
from pydantic import BaseModel, Field
from typing import Optional

app = FastAPI(
    title="API de Cuentas, Ahorro, Negocio e IA de Precios",
    version="1.0.0",
    description="Backend para la gestión de finanzas personales, inventario y costeo por escalas con IA."
)

# Permitir conexión desde la app Flutter Móvil y Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

pricing_agent = PricingAgent()

# Schemas
class PricingAnalysisRequest(BaseModel):
    product_name: str = Field(..., example="Polera de algodón básica")
    total_purchase_cost: float = Field(..., gt=0, example=1200.0)
    batch_units: int = Field(..., gt=0, example=50)
    country_code: str = Field(default="BO", example="BO")
    extra_notes: Optional[str] = Field(default="", example="Comprado en fardo mayorista")

@app.get("/")
def health_check():
    return {
        "status": "online",
        "message": "Servicio de Finanzas e IA de Precios activo",
        "version": "1.0.0"
    }

@app.post("/api/ai/analyze-pricing")
def analyze_product_pricing(req: PricingAnalysisRequest):
    """
    Desglosa el costo de compra de un lote y entrega sugerencias de precios
    de venta por Unidad, Media Docena y Docena adaptadas al país.
    """
    analysis = pricing_agent.analyze_pricing(
        product_name=req.product_name,
        total_purchase_cost=req.total_purchase_cost,
        batch_units=req.batch_units,
        country_code=req.country_code,
        extra_notes=req.extra_notes or ""
    )
    return analysis

@app.get("/api/ai/seasonal-trends/{country_code}")
def get_seasonal_trends(country_code: str = "BO"):
    """
    Retorna qué productos son los más demandados y qué conviene vender según el mes y país.
    """
    return SeasonalTrendsService.get_current_opportunities(country_code=country_code)
