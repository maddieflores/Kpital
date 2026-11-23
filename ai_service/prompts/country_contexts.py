"""
Perfiles y contextos macroeconómicos y comerciales por país.
Permiten a la IA generar recomendaciones realistas y aterrizadas a la economía local.
"""

COUNTRY_PROFILES = {
    "BO": {
        "country_name": "Bolivia",
        "currency_code": "BOB",
        "currency_symbol": "Bs",
        "market_characteristics": """
- Mercado altamente comercial, ferias populares (La Cancha en Cbba, 16 de Julio en El Alto, Los Pozos/La Ramada en SCZ).
- Fuerte uso del pago por QR Simple (sin comisiones o comisiones bancarias mínimas).
- Presencia de importaciones en dólares paralelos; los costos de reposición deben vigilarse cuidadosamente.
- Métodos de venta comunes: venta al detalle/unidad en tiendas/puestos y venta por mayor (por docena o fardo).
- La venta por docena típicamente ofrece un descuento del 15% al 25% respecto a comprar 12 unidades individuales, incentivando volumen.
""",
        "seasonal_calendar": {
            "1-2": "Temporada Escolar (mochilas, guardapolvos, útiles) y Carnaval (espumas, ponchos, pistolas de agua, serpentina).",
            "3-4": "Otoño / Cuaresma / Semana Santa (pescados, abarrotes, repostería).",
            "5": "Día de la Madre (mayo 27) - Mayor pico comercial de regalos, electrodomésticos pequeños, flores, tortas.",
            "6-7": "Invierno / San Juan (ropa térmica, chompas, frazadas, estufas, embutidos y bebidas calientes).",
            "8-9": "Fiestas patrias (agosto) y Día del Estudiante / Primavera / Amor (septiembre) - Flores, peluches, tecnología básica.",
            "10-11": "Todos Santos (masitas, flores) y compras anticipadas de mercadería navideña antes de subidas de frontera.",
            "12": "Navidad y Fin de Año - Juguetes, luces, panetones, sidras, ropa nueva de fiesta."
        },
        "evergreen_products": [
            "Abarrotes y alimentos no perecederos (arroz, fideo, aceite)",
            "Accesorios de celular (cables tipo C, cargadores, vidrios templados)",
            "Artículos de limpieza e higiene personal",
            "Ropa interior y medias al por mayor",
            "Comida rápida y snacks al paso"
        ]
    },
    "AR": {
        "country_name": "Argentina",
        "currency_code": "ARS",
        "currency_symbol": "$",
        "market_characteristics": """
- Entorno de inflación periódica: los precios deben actualizarse con frecuencia para no descapitalizarse.
- Vital importancia del costo de reposición: calcular el precio de venta en base a lo que costará comprar el próximo lote.
- Medios de pago: Mercado Pago (QR y transferencias), débito y efectivo con descuentos por pago al contado.
""",
        "seasonal_calendar": {
            "2-3": "Vuelta a clases escolar.",
            "5-7": "Temporada de invierno y abrigo.",
            "8": "Día de las Infancias (Día del Niño) - Juguetes y entretenimiento.",
            "10": "Día de la Madre.",
            "12": "Fiestas de fin de año y vacaciones de verano."
        },
        "evergreen_products": [
            "Alimentos esenciales",
            "Artículos de farmacia y limpieza",
            "Cafetería y panadería",
            "Servicios de reparación y mantenimiento"
        ]
    }
}

def get_country_context(country_code: str = "BO") -> dict:
    return COUNTRY_PROFILES.get(country_code.upper(), COUNTRY_PROFILES["BO"])
