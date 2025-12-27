 -- Milk Records Table--
 CREATE TABLE milk_records (
    id SERIAL PRIMARY KEY,
    record_date DATE NOT NULL,
    milk_type VARCHAR(100) NOT NULL, -- 'Whole Farm', 'Individual Goat'
    total_produced INT NOT NULL,
    total_used INT NOT NULL,
    available INT GENERATED ALWAYS AS (total_produced - total_used) STORED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

 -- Transactions Tables--
 CREATE TABLE income_transactions (
    id SERIAL PRIMARY KEY,
    transaction_date DATE NOT NULL,
    income_type VARCHAR(100) NOT NULL, -- 'Milk Sale', 'Goat Sale', 'Category Income', 'Other'
    category VARCHAR(100),
    quantity DECIMAL(10,2),
    price_per_unit DECIMAL(10,2),
    amount DECIMAL(10,2) NOT NULL,
    receipt_no VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expense_transactions (
    id SERIAL PRIMARY KEY,
    transaction_date DATE NOT NULL,
    expense_type VARCHAR(100) NOT NULL, -- 'category expense', 'Other'
    category VARCHAR(100),
    quantity DECIMAL(10,2),
    price_per_unit DECIMAL(10,2),
    amount DECIMAL(10,2) NOT NULL,
    receipt_no VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);