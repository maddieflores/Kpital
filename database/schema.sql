-- ====================================================================
-- ESQUEMA DE BASE DE DATOS: APP FINANCIERA, NEGOCIO E IA DE PRECIOS
-- Compatible con PostgreSQL y Supabase
-- ====================================================================

-- Extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABLA DE USUARIOS Y PLANES (Incluye rol 'owner' para ti y planes 'free'/'pro')
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,       -- Ej: 'maddie'
    email VARCHAR(255) UNIQUE NOT NULL,         -- Correo real para recuperación (addelynie@gmail.com)
    full_name VARCHAR(150),                     -- 'Madeline Flores'
    phone_number VARCHAR(30),                   -- Teléfono para códigos SMS/WhatsApp (69069393)
    password_hash VARCHAR(255),                 -- Hash seguro de contraseña
    is_verified BOOLEAN DEFAULT FALSE,          -- Estado de verificación por email o teléfono
    country_code VARCHAR(5) DEFAULT 'BO',       -- 'BO' (Bolivia), 'AR' (Argentina), etc.
    currency VARCHAR(5) DEFAULT 'BOB',          -- 'BOB', 'ARS', 'USD'
    role VARCHAR(20) DEFAULT 'user',            -- 'owner', 'admin', 'user'
    plan VARCHAR(50) DEFAULT 'free',            -- 'owner', 'pro', 'free'
    plan_expires_at TIMESTAMP WITH TIME ZONE,
    monthly_ai_queries_used INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CUENTAS FINANCIERAS Y BÓVEDAS DE AHORRO
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,                 -- Ej: 'Efectivo en mano', 'Banco Unión QR', 'BCP', 'Tigo Money'
    type VARCHAR(30) NOT NULL,                  -- 'cash', 'bank', 'digital_wallet', 'savings_vault'
    currency VARCHAR(5) DEFAULT 'BOB',
    balance NUMERIC(14, 2) DEFAULT 0.00,        -- Saldo actual en esta cuenta
    is_savings_vault BOOLEAN DEFAULT FALSE,     -- TRUE si es una bóveda de ahorro que no se debe tocar
    color_hex VARCHAR(10) DEFAULT '#2196F3',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CATEGORÍAS DE INGRESOS Y GASTOS
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL si es del sistema
    name VARCHAR(100) NOT NULL,
    type VARCHAR(10) NOT NULL,                  -- 'income' o 'expense'
    icon VARCHAR(50) DEFAULT 'attach_money',
    is_essential BOOLEAN DEFAULT TRUE,          -- Para clasificar gastos fijos vs gastos hormiga
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TRANSACCIONES (Ingresos, Gastos y Transferencias entre cuentas)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    destination_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL, -- Para transferencias entre cuentas propias
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    type VARCHAR(15) NOT NULL,                  -- 'income', 'expense', 'transfer'
    amount NUMERIC(14, 2) NOT NULL,
    currency VARCHAR(5) DEFAULT 'BOB',
    contact_name VARCHAR(150),                  -- Quién transfirió o a quién se le pagó
    description TEXT,                           -- En qué se gastó o concepto
    receipt_image_url TEXT,                     -- Foto o captura de comprobante bancario / QR
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. DEUDAS Y PRÉSTAMOS (Cuentas por Cobrar y por Pagar)
CREATE TABLE debts_and_loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,                  -- 'receivable' (me deben) | 'payable' (yo debo)
    person_name VARCHAR(150) NOT NULL,          -- Nombre de la persona o entidad
    phone_number VARCHAR(30),                   -- Para enviar recordatorio por WhatsApp
    total_amount NUMERIC(14, 2) NOT NULL,
    remaining_amount NUMERIC(14, 2) NOT NULL,
    due_date DATE,                              -- Fecha pactada de pago
    status VARCHAR(20) DEFAULT 'pending',       -- 'pending', 'partial', 'paid'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Historial de abonos parciales a una deuda o préstamo
CREATE TABLE debt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    debt_id UUID NOT NULL REFERENCES debts_and_loans(id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL, -- Cuenta donde entró o salió el abono
    amount_paid NUMERIC(14, 2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    note TEXT
);

-- 6. METAS DE AHORRO (Vinculadas a las Bóvedas)
CREATE TABLE savings_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE, -- Bóveda donde está el dinero
    title VARCHAR(150) NOT NULL,                -- Ej: 'Capital para lote de invierno', 'Fondo de emergencia'
    target_amount NUMERIC(14, 2) NOT NULL,
    current_amount NUMERIC(14, 2) DEFAULT 0.00,
    deadline DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. PRODUCTOS Y COSTEO DE NEGOCIO (Inventario con escalas: unidad, media docena, docena)
CREATE TABLE business_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Datos de compra por lote / mayorista
    batch_package_type VARCHAR(50) DEFAULT 'paquete', -- 'fardo', 'caja', 'docena', 'paquete', 'unidad'
    batch_quantity INT NOT NULL,                      -- Cuántas unidades vienen en el lote comprado
    total_purchase_cost NUMERIC(14, 2) NOT NULL,      -- Cuánto te costó comprar todo el lote
    
    -- Costeo unitario y por escalas (calculados automáticamente)
    unit_cost NUMERIC(14, 2) NOT NULL,                -- total_purchase_cost / batch_quantity
    half_dozen_cost NUMERIC(14, 2),                   -- unit_cost * 6
    dozen_cost NUMERIC(14, 2),                        -- unit_cost * 12
    
    -- Precios de venta al público fijados
    sale_price_unit NUMERIC(14, 2) NOT NULL,
    sale_price_half_dozen NUMERIC(14, 2),
    sale_price_dozen NUMERIC(14, 2),
    
    -- Stock y estado
    stock_units INT DEFAULT 0,
    min_stock_alert INT DEFAULT 5,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. VENTAS DEL NEGOCIO
CREATE TABLE business_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES business_products(id) ON DELETE CASCADE,
    sale_scale VARCHAR(20) NOT NULL,            -- 'unit', 'half_dozen', 'dozen', 'batch'
    quantity INT NOT NULL,                      -- Cantidad vendida en esa escala
    unit_sale_price NUMERIC(14, 2) NOT NULL,
    total_sale_amount NUMERIC(14, 2) NOT NULL,
    profit_margin_amount NUMERIC(14, 2) NOT NULL, -- Ganancia neta de la venta
    payment_method VARCHAR(30) DEFAULT 'cash',  -- 'cash', 'qr', 'transfer'
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL, -- Cuenta donde ingresó el dinero
    sale_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. HISTORIAL DE CONSULTAS CON LA IA DE PRECIOS Y TENDENCIAS
CREATE TABLE ai_consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consultation_type VARCHAR(50) NOT NULL,     -- 'pricing_recommendation', 'seasonal_trends', 'receipt_ocr'
    country_code VARCHAR(5) DEFAULT 'BO',
    user_input_prompt TEXT NOT NULL,
    ai_recommendation_json JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_transactions_user ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_products_user ON business_products(user_id);
CREATE INDEX idx_debts_user ON debts_and_loans(user_id, status);

-- ====================================================================
-- SEED DATA: CUENTA OWNER OFICIAL (MADELINE FLORES)
-- ====================================================================
INSERT INTO users (
    id,
    username,
    email,
    full_name,
    phone_number,
    country_code,
    currency,
    role,
    plan,
    is_verified
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'maddie',
    'addelynie@gmail.com',
    'Madeline Flores',
    '+59169069393',
    'BO',
    'BOB',
    'owner',
    'owner',
    TRUE
) ON CONFLICT (email) DO NOTHING;
