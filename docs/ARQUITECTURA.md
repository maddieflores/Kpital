# Arquitectura del Proyecto: App de Finanzas, Ahorro, Negocio e IA de Precios

## 1. Visión General
Esta solución integra finanzas personales con herramientas para micro-comerciantes y emprendedores, con asistencia de IA contextualizada a la economía de **Bolivia** y **Latinoamérica** (Bolivia, Argentina, etc.).

## 2. Estructura del Repositorio

* `database/`:
  * `schema.sql`: Esquema relacional en PostgreSQL / Supabase con soporte para usuarios (roles `owner` y `user`), planes `free`/`pro`, cuentas bancarias/efectivo/bóvedas, transacciones, deudas/préstamos con abonos parciales, inventario de productos por escalas (lote, unidad, media docena, docena) y registro de consultas con IA.
* `backend/`:
  * API en FastAPI (Python 3.12).
  * Endpoints REST para cálculos de márgenes, evaluación de precios y tendencias estacionales de mercado.
* `ai_service/`:
  * `pricing_agent.py`: Orquestador de análisis de costos de compra y recomendación de precios de venta sugeridos.
  * `calculators/cost_breakdown.py`: Motor matemático para desglosar lotes en costos unitarios, por 6 unidades y por 12 unidades, y márgenes de ganancia.
  * `prompts/country_contexts.py`: Base de conocimiento económico local (Bolivia: QR Simple, ferias, informalidad, temporadas; Argentina: inflación y reposición).
  * `seasonal_trends.py`: Recomendador de qué productos vender según el mes actual y productos evergreen de alta rotación.
* `frontend/`:
  * Aplicación móvil y web responsiva construida con Flutter (Dart) para Android, iOS y Navegador Web.
* `docs/`:
  * Guías de instalación, ejecución y diseño del sistema.

## 3. Modelo de Roles y Monetización
* **Usuario Owner (Tú):** Acceso permanente sin costo, sin límites de consultas con IA, con todos los módulos comerciales y de finanzas desbloqueados para registrar tus finanzas y ventas reales.
* **Usuarios Regulares:**
  * Plan Gratuito: Registro básico de gastos e ingresos, 1 cuenta, cuota mensual de IA.
  * Plan Pro: Inventario ilimitado, costeo por escalas, IA ilimitada, OCR de comprobantes QR y exportación contable a Excel/PDF.
