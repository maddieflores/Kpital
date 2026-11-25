"""
Punto de entrada de la API Backend (FastAPI)
Conecta la base de datos, el recomendador de precios con IA y la gestión financiera.
"""

import os
from contextlib import asynccontextmanager, closing

from fastapi import FastAPI
from starlette.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from ai_service.pricing_agent import PricingAgent
from ai_service.seasonal_trends import SeasonalTrendsService
from .api.auth_routes import router as auth_router
from .api.finance_routes import router as finance_router
from pydantic import BaseModel, Field
from typing import Optional


def check_and_init_database(database_url: str) -> None:
    import psycopg2

    try:
        with closing(psycopg2.connect(database_url, connect_timeout=5)) as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS public.accounts (
                        id VARCHAR(64) PRIMARY KEY,
                        user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                        name VARCHAR(100) NOT NULL,
                        type VARCHAR(30) NOT NULL,
                        currency VARCHAR(5) DEFAULT 'BOB',
                        balance NUMERIC(14, 2) DEFAULT 0.00,
                        is_savings_vault BOOLEAN DEFAULT FALSE,
                        target_amount NUMERIC(14, 2),
                        color_hex VARCHAR(10) DEFAULT '#3366D6',
                        created_at TIMESTAMPTZ DEFAULT NOW()
                    );
                    ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS target_amount NUMERIC(14, 2);
                    ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS color_hex VARCHAR(10) DEFAULT '#3366D6';

                    CREATE TABLE IF NOT EXISTS public.transactions (
                        id VARCHAR(64) PRIMARY KEY,
                        user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                        account_id VARCHAR(64) NOT NULL,
                        account_name VARCHAR(100),
                        destination_account_id VARCHAR(64),
                        destination_account_name VARCHAR(100),
                        type VARCHAR(20) NOT NULL,
                        amount NUMERIC(14, 2) NOT NULL,
                        currency VARCHAR(5) DEFAULT 'BOB',
                        contact_name VARCHAR(150),
                        description TEXT,
                        category VARCHAR(100),
                        receipt_image_url TEXT,
                        transaction_date TIMESTAMPTZ DEFAULT NOW(),
                        created_at TIMESTAMPTZ DEFAULT NOW()
                    );
                    CREATE INDEX IF NOT EXISTS accounts_user_id_idx ON public.accounts(user_id);
                    CREATE INDEX IF NOT EXISTS transactions_user_id_idx ON public.transactions(user_id);
                    CREATE INDEX IF NOT EXISTS transactions_account_id_idx ON public.transactions(account_id);
                """)
            connection.commit()
    except psycopg2.Error as e:
        print(f"Error inicializando tablas en PostgreSQL: {e}")
        raise RuntimeError("No se pudo conectar o inicializar PostgreSQL.") from None


@asynccontextmanager
async def lifespan(_app: FastAPI):
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        await run_in_threadpool(check_and_init_database, database_url)
    yield


app = FastAPI(
    title="API de Cuentas, Ahorro, Negocio e IA de Precios",
    version="1.0.0",
    description="Backend para la gestión de finanzas personales, inventario y costeo por escalas con IA.",
    lifespan=lifespan,
)

# Permitir conexión desde la app Flutter Móvil y Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(finance_router)

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
