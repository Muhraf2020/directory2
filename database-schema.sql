-- =====================================================
-- SCRATCH & DENT DIRECTORY - DATABASE SCHEMA
-- =====================================================
-- Run this in Supabase SQL Editor to set up your database

-- =====================================================
-- CREATE TABLES
-- =====================================================

-- States table
CREATE TABLE states (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  emoji VARCHAR(10),
  store_count INT DEFAULT 0,
  city_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Cities table
CREATE TABLE cities (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  state_id INT REFERENCES states(id) ON DELETE CASCADE,
  store_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(slug, state_id)
);

-- Stores table
CREATE TABLE stores (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255),
  city_id INT REFERENCES cities(id) ON DELETE CASCADE,
  state_id INT REFERENCES states(id) ON DELETE CASCADE,
  phone VARCHAR(20),
  website VARCHAR(255),
  email VARCHAR(100),
  description TEXT,
  hours JSONB,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_cities_state ON cities(state_id);
CREATE INDEX idx_stores_city ON stores(city_id);
CREATE INDEX idx_stores_state ON stores(state_id);
CREATE INDEX idx_states_slug ON states(slug);
CREATE INDEX idx_cities_slug ON cities(slug);
CREATE INDEX idx_stores_name ON stores(name);

-- =====================================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE states ENABLE ROW LEVEL SECURITY;
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Public read access" ON states FOR SELECT USING (true);
CREATE POLICY "Public read access" ON cities FOR SELECT USING (true);
CREATE POLICY "Public read access" ON stores FOR SELECT USING (true);

-- =====================================================
-- CREATE TRIGGER FUNCTION TO AUTO-UPDATE COUNTS
-- =====================================================

CREATE OR REPLACE FUNCTION update_store_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Update city count
    UPDATE cities 
    SET store_count = (
      SELECT COUNT(*) FROM stores WHERE city_id = NEW.city_id
    )
    WHERE id = NEW.city_id;
    
    -- Update state counts
    UPDATE states 
    SET 
      store_count = (SELECT COUNT(*) FROM stores WHERE state_id = NEW.state_id),
      city_count = (SELECT COUNT(DISTINCT city_id) FROM stores WHERE state_id = NEW.state_id)
    WHERE id = NEW.state_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Update city count
    UPDATE cities 
    SET store_count = (
      SELECT COUNT(*) FROM stores WHERE city_id = OLD.city_id
    )
    WHERE id = OLD.city_id;
    
    -- Update state counts
    UPDATE states 
    SET 
      store_count = (SELECT COUNT(*) FROM stores WHERE state_id = OLD.state_id),
      city_count = (SELECT COUNT(DISTINCT city_id) FROM stores WHERE state_id = OLD.state_id)
    WHERE id = OLD.state_id;
    
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Update old city count
    UPDATE cities 
    SET store_count = (
      SELECT COUNT(*) FROM stores WHERE city_id = OLD.city_id
    )
    WHERE id = OLD.city_id;
    
    -- Update new city count
    UPDATE cities 
    SET store_count = (
      SELECT COUNT(*) FROM stores WHERE city_id = NEW.city_id
    )
    WHERE id = NEW.city_id;
    
    -- Update old state counts
    UPDATE states 
    SET 
      store_count = (SELECT COUNT(*) FROM stores WHERE state_id = OLD.state_id),
      city_count = (SELECT COUNT(DISTINCT city_id) FROM stores WHERE state_id = OLD.state_id)
    WHERE id = OLD.state_id;
    
    -- Update new state counts
    UPDATE states 
    SET 
      store_count = (SELECT COUNT(*) FROM stores WHERE state_id = NEW.state_id),
      city_count = (SELECT COUNT(DISTINCT city_id) FROM stores WHERE state_id = NEW.state_id)
    WHERE id = NEW.state_id;
    
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CREATE TRIGGER
-- =====================================================

CREATE TRIGGER update_counts_trigger
AFTER INSERT OR UPDATE OR DELETE ON stores
FOR EACH ROW EXECUTE FUNCTION update_store_counts();

-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================

-- Insert sample states
INSERT INTO states (name, slug, emoji) VALUES
('Florida', 'florida', '🌴'),
('Texas', 'texas', '⭐'),
('California', 'california', '🌴'),
('Pennsylvania', 'pennsylvania', '📍'),
('Georgia', 'georgia', '🍑'),
('Illinois', 'illinois', '🌆'),
('Ohio', 'ohio', '📍'),
('Missouri', 'missouri', '📍');

-- Insert sample cities for Florida
INSERT INTO cities (name, slug, state_id) VALUES
('Miami', 'miami', 1),
('Orlando', 'orlando', 1),
('Tampa', 'tampa', 1),
('Jacksonville', 'jacksonville', 1);

-- Insert sample cities for Texas
INSERT INTO cities (name, slug, state_id) VALUES
('Houston', 'houston', 2),
('Dallas', 'dallas', 2),
('Austin', 'austin', 2),
('San Antonio', 'san-antonio', 2);

-- Insert sample cities for California
INSERT INTO cities (name, slug, state_id) VALUES
('Los Angeles', 'los-angeles', 3),
('San Diego', 'san-diego', 3),
('San Francisco', 'san-francisco', 3),
('Sacramento', 'sacramento', 3);

-- Insert sample stores
INSERT INTO stores (name, address, city_id, state_id, phone, website, description) VALUES
('Miami Appliance Outlet', '123 Biscayne Blvd, Miami, FL 33132', 1, 1, '305-555-0101', 'https://example.com', 'Quality scratch and dent appliances with factory warranties. Serving Miami for over 15 years.'),
('Orlando Discount Appliances', '456 International Dr, Orlando, FL 32819', 2, 1, '407-555-0102', 'https://example.com', 'Family-owned appliance outlet specializing in discounted refrigerators, washers, and dryers.'),
('Tampa Appliance Warehouse', '789 Dale Mabry Hwy, Tampa, FL 33609', 3, 1, '813-555-0103', 'https://example.com', 'Large selection of scratch and dent appliances from all major brands.'),
('Houston Scratch & Dent', '321 Westheimer Rd, Houston, TX 77027', 5, 2, '713-555-0201', 'https://example.com', 'Houston''s premier destination for discount appliances. Open 7 days a week.'),
('Dallas Appliance Center', '654 Commerce St, Dallas, TX 75202', 6, 2, '214-555-0202', 'https://example.com', 'Serving Dallas with quality appliances at unbeatable prices since 2005.'),
('LA Appliance Depot', '987 Sunset Blvd, Los Angeles, CA 90028', 9, 3, '323-555-0301', 'https://example.com', 'Los Angeles'' largest inventory of scratch and dent appliances. Free delivery available.'),
('San Diego Discount Outlet', '147 Market St, San Diego, CA 92101', 10, 3, '619-555-0302', 'https://example.com', 'Save up to 70% on name-brand appliances with minor cosmetic imperfections.');

-- =====================================================
-- VERIFY INSTALLATION
-- =====================================================

-- Check that everything was created successfully
SELECT 'States:', COUNT(*) FROM states;
SELECT 'Cities:', COUNT(*) FROM cities;
SELECT 'Stores:', COUNT(*) FROM stores;

-- Display state counts (should be automatically calculated)
SELECT name, store_count, city_count FROM states ORDER BY store_count DESC;
