
-- 1. Create users table
CREATE TABLE IF NOT EXISTS users (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
username VARCHAR(50) UNIQUE NOT NULL,
email VARCHAR(100) UNIQUE NOT NULL,
password_hash VARCHAR(255),
full_name VARCHAR(100),
google_id VARCHAR(100) UNIQUE,
avatar_url VARCHAR(500),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
last_login TIMESTAMP,
is_active BOOLEAN DEFAULT true
);

-- 2. Create goats table
CREATE TABLE IF NOT EXISTS goats (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
tag_no VARCHAR(50) UNIQUE NOT NULL,
name VARCHAR(100),
breed VARCHAR(50),
gender VARCHAR(10) CHECK (gender IN ('Male', 'Female')) NOT NULL,
goat_stage VARCHAR(50),
date_of_birth DATE,
date_of_entry DATE,
weight NUMERIC(6,2),
goat_group VARCHAR(50),
obtained_from VARCHAR(100),
mother_tag VARCHAR(50),
father_tag VARCHAR(50),
notes TEXT,
photo_path VARCHAR(500),
breeding_status VARCHAR(50) DEFAULT 'Not Bred',
breeding_date DATE,
breeding_partner VARCHAR(50),
kidding_due_date DATE,
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
is_active BOOLEAN DEFAULT true
);

-- 3. Create weight_history table
CREATE TABLE IF NOT EXISTS weight_history (
id SERIAL PRIMARY KEY,
goat_id UUID REFERENCES goats(id) ON DELETE CASCADE,
weight NUMERIC(6,2) NOT NULL,
measurement_date DATE NOT NULL,
notes TEXT,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create kidding_history table
CREATE TABLE IF NOT EXISTS kidding_history (
id SERIAL PRIMARY KEY,
goat_id UUID REFERENCES goats(id) ON DELETE CASCADE,
kidding_date DATE NOT NULL,
number_of_kids INTEGER DEFAULT 1,
kids_gender VARCHAR(50),
kids_weight NUMERIC(6,2),
notes TEXT,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create events table
CREATE TABLE IF NOT EXISTS events (
id SERIAL PRIMARY KEY,
title VARCHAR(200) NOT NULL,
description TEXT,
event_type VARCHAR(50) CHECK (event_type IN ('Health', 'Vaccination', 'Breeding', 'Kidding', 'Weaning', 'Milking', 'Other')),
event_date DATE NOT NULL,
event_time TIME,
goats_involved TEXT, -- Comma separated tag numbers
location VARCHAR(100),
notes TEXT,
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Create milk_records table
CREATE TABLE IF NOT EXISTS milk_records (
id SERIAL PRIMARY KEY,
goat_id UUID REFERENCES goats(id) ON DELETE CASCADE,
milking_date DATE NOT NULL,
morning_quantity NUMERIC(6,2),
evening_quantity NUMERIC(6,2),
total_quantity NUMERIC(6,2) GENERATED ALWAYS AS (COALESCE(morning_quantity, 0) + COALESCE(evening_quantity, 0)) STORED,
notes TEXT,
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Create incomes table
CREATE TABLE IF NOT EXISTS incomes (
id SERIAL PRIMARY KEY,
income_type VARCHAR(50) CHECK (income_type IN ('Milk Sale', 'Goat Sale', 'Manure Sale', 'Other')),
amount NUMERIC(10,2) NOT NULL,
description VARCHAR(200),
transaction_date DATE NOT NULL,
buyer_name VARCHAR(100),
buyer_contact VARCHAR(50),
notes TEXT,
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
id SERIAL PRIMARY KEY,
expense_type VARCHAR(50) CHECK (expense_type IN ('Feed', 'Medicine', 'Equipment', 'Labor', 'Transport', 'Utilities', 'Other')),
amount NUMERIC(10,2) NOT NULL,
description VARCHAR(200),
transaction_date DATE NOT NULL,
vendor_name VARCHAR(100),
vendor_contact VARCHAR(50),
notes TEXT,
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Create notes table
CREATE TABLE IF NOT EXISTS notes (
id SERIAL PRIMARY KEY,
title VARCHAR(200) NOT NULL,
content TEXT NOT NULL,
note_type VARCHAR(50) DEFAULT 'General',
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
email VARCHAR(100),
synced BOOLEAN DEFAULT true,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Create farm_settings table
CREATE TABLE IF NOT EXISTS farm_settings (
id SERIAL PRIMARY KEY,
farm_name VARCHAR(100),
farm_location VARCHAR(200),
owner_name VARCHAR(100),
contact_number VARCHAR(20),
email VARCHAR(100),
currency VARCHAR(10) DEFAULT 'INR',
milk_unit VARCHAR(10) DEFAULT 'L',
weight_unit VARCHAR(10) DEFAULT 'kg',
user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Create indexes for better performance
CREATE INDEX idx_goats_user_id ON goats(user_id);
CREATE INDEX idx_goats_tag_no ON goats(tag_no);
CREATE INDEX idx_goats_breeding_status ON goats(breeding_status);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_event_date ON events(event_date);
CREATE INDEX idx_milk_records_user_id ON milk_records(user_id);
CREATE INDEX idx_milk_records_goat_id ON milk_records(goat_id);
CREATE INDEX idx_incomes_user_id ON incomes(user_id);
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_weight_history_goat_id ON weight_history(goat_id);
CREATE INDEX idx_kidding_history_goat_id ON kidding_history(goat_id);
CREATE INDEX idx_notes_user_id ON notes(user_id);

-- 12. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ language 'plpgsql';

-- 13. Create triggers for updated_at
CREATE TRIGGER update_goats_updated_at
BEFORE UPDATE ON goats
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_events_updated_at
BEFORE UPDATE ON events
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_farm_settings_updated_at
BEFORE UPDATE ON farm_settings
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
