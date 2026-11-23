"""
Calculadora matemática para costeo de mercadería y escalas de venta.
Permite descomponer compras por lote (fardos, cajas, paquetes) en:
- Costo unitario
- Costo por media docena (6 unidades)
- Costo por docena (12 unidades)
- Cálculo de márgenes brutos y puntos de equilibrio.
"""

from typing import Dict, Any

class CostBreakdownCalculator:
    
    @staticmethod
    def calculate_cost_scales(batch_total_cost: float, batch_units: int) -> Dict[str, float]:
        """
        Calcula el costo base por unidad, media docena y docena a partir de una compra por lote.
        """
        if batch_units <= 0:
            raise ValueError("La cantidad de unidades en el lote debe ser mayor a 0.")
            
        unit_cost = round(batch_total_cost / batch_units, 2)
        half_dozen_cost = round(unit_cost * 6, 2)
        dozen_cost = round(unit_cost * 12, 2)
        
        return {
            "batch_total_cost": round(batch_total_cost, 2),
            "batch_units": batch_units,
            "unit_cost": unit_cost,
            "half_dozen_cost": half_dozen_cost,
            "dozen_cost": dozen_cost,
        }

    @staticmethod
    def calculate_margins_and_profit(
        cost: float,
        sale_price: float,
        units_sold: int = 1
    ) -> Dict[str, Any]:
        """
        Calcula la ganancia monetaria y el porcentaje de margen sobre el precio de venta.
        Margen (%) = ((Precio Venta - Costo) / Precio Venta) * 100
        Markup (%) = ((Precio Venta - Costo) / Costo) * 100
        """
        if sale_price <= 0:
            return {"error": "El precio de venta debe ser superior a 0"}
            
        profit_per_unit = round(sale_price - cost, 2)
        total_profit = round(profit_per_unit * units_sold, 2)
        
        margin_percent = round((profit_per_unit / sale_price) * 100, 2)
        markup_percent = round((profit_per_unit / cost) * 100, 2) if cost > 0 else 100.0
        
        is_healthy_margin = margin_percent >= 25.0  # Margen saludable recomendado en comercio
        
        return {
            "cost": cost,
            "sale_price": sale_price,
            "units_sold": units_sold,
            "profit_per_unit": profit_per_unit,
            "total_profit": total_profit,
            "margin_percent": margin_percent,
            "markup_percent": markup_percent,
            "is_healthy_margin": is_healthy_margin,
            "status": "profitable" if profit_per_unit > 0 else "loss"
        }
        
    @staticmethod
    def break_even_point(fixed_costs: float, unit_sale_price: float, unit_cost: float) -> int:
        """
        Calcula cuántas unidades se deben vender para no perder dinero (Punto de Equilibrio).
        """
        contribution_margin = unit_sale_price - unit_cost
        if contribution_margin <= 0:
            return -1  # Imposible llegar al punto de equilibrio vendiendo a pérdida
        return int(-(-fixed_costs // contribution_margin))  # Redondeo hacia arriba
