# 💎 Kpital — Tu capital, en calma

**Kpital** es una solución integral y moderna de finanzas personales, gestión de micro-negocios por escalas, bóvedas de ahorro inteligente y asistente de precios impulsado por Inteligencia Artificial, diseñada específicamente para el contexto económico de Bolivia y Latinoamérica.

---

## 🚀 Módulos Implementados al 100%

### 1. 💰 Flujo de Dinero y Transferencias (Ingresos)
* **CU-1.1:** Registro de transferencias con emisor (*Doña Rosa, Cliente QR*), monto, fecha, hora y cuenta receptora (*Banco Unión QR, BCP Soli, Efectivo*).
* **CU-1.2:** Adjunto de comprobantes y capturas QR con visor de alta definición.
* **CU-1.3:** Transferencias internas entre cuentas y hacia bóvedas sin computarse como gasto.
* **CU-1.4:** Buscador y filtros dinámicos por contacto, período y tipo de movimiento.

### 2. 📉 Gastos y Categorías Detalladas (Egresos)
* **CU-2.1:** Registro rápido de gastos con método de pago (*Efectivo, QR, Débito*) y cuenta de origen.
* **CU-2.2:** Clasificación inteligente entre **Gasto Fijo** (*alquiler, luz, insumos*) y **Gasto Hormiga** (*antojos, comidas al paso*).
* **CU-2.3:** Gráfico circular interactivo (`fl_chart`) con porcentaje de categorías y alerta de impacto de gastos hormiga.

### 3. 🤝 Préstamos y Deudas (Cuentas por Cobrar y por Pagar)
* **CU-3.1:** Registro de cuentas por cobrar (*"Me deben"*) con deudor, monto y fecha límite pactada.
* **CU-3.2:** Abonos parciales inteligentes: descuenta automáticamente la deuda y abona el dinero directo a la cuenta bancaria seleccionada.
* **CU-3.3:** Cobrador de WhatsApp: mensaje pre-redactado cortés con saldo pendiente y botón de apertura directa.
* **CU-3.4:** Registro de cuentas por pagar (*"Debo a proveedores/bancos"*).

### 4. 🏦 Cuentas, Bóvedas de Ahorro y Estadísticas
* **CU-4.1:** Cuentas personalizadas con identidad local (*Banco Unión, Efectivo Mostrador, BCP Soli, BNB*).
* **CU-4.2:** Bóvedas de Ahorro con metas fijas (*ej. 8.000 Bs para fardo de invierno*).
* **CU-4.3:** Bloqueo de Bóveda: saldo blindado que no suma en el "disponible para gastar diario".
* **CU-4.4:** Balance general en tiempo real del patrimonio neto consolidado.

### 5. 📦 Micro-negocio, Inversión e Inventario por Escalas
* **CU-5.1:** Compra de lote mayorista (*fardos, cajas, docenas*).
* **CU-5.2:** Escandallo automático: costo unitario, costo por media docena ($x6$) y por docena ($x12$).
* **CU-5.3:** Fijación de precios por escala con visualización de margen neto de ganancia.
* **CU-5.4:** Venta rápida por QR con descuento automático de stock y depósito a cuenta bancaria.
* **CU-5.5:** Métrica de Capital Invertido vs. Capital Recuperado y utilidades netas.

### 6. 🧠 Asistente IA de Precios y Oportunidades
* **CU-6.1:** Evaluador de compras con IA para ferias y mercados mayoristas.
* **CU-6.2:** Recomendador de precios sugeridos al detalle y por docena adaptado a Bolivia 🇧🇴 o Argentina 🇦🇷.
* **CU-6.3:** Radar de Temporadas: productos más vendidos del mes actual, catálogo evergreen y calculadora de la **Regla 70/30** de reparto de capital.

### 7. 📢 Monetización Inteligente con Anuncios (Google AdMob)
* **CU-7.1:** Banner inferior no invasivo en pantallas de estadísticas y tendencias.
* **CU-7.2:** Video publicitario con recompensa de 15 segundos para desbloquear análisis de precios IA para usuarios comunes.
* **CU-7.3:** **Modo Creador (Owner):** Desactivación del 100% de la publicidad con bypass directo e instantáneo a la IA para la cuenta del dueño.

---

## 🛠️ Estructura del Proyecto

```plaintext
├── ai_service/         # Motor de Inteligencia Artificial (FastAPI / LangChain / Gemini)
├── backend/            # Backend API en FastAPI con autenticación y gestión de datos
├── database/           # Scripts SQL y esquema de base de datos relacional (PostgreSQL / Supabase)
├── frontend/           # Aplicación multiplataforma en Flutter (Android, iOS, Web, Windows)
└── docs/               # Documentación técnica y diagramas de arquitectura
```

---

## 🏃 Instrucciones de Ejecución Local

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

### Backend (FastAPI)
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
