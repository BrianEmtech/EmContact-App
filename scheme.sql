-- Updated schema.sql
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    employee_number VARCHAR(50) UNIQUE NOT NULL, -- Unique business ID
    full_name VARCHAR(255) NOT NULL,              -- 
    email VARCHAR(255) UNIQUE NOT NULL,          -- 
    contact VARCHAR(20),                         -- 
    linkedin_url TEXT,
    residence TEXT,
    team_name VARCHAR(100),
    appraisal_results DECIMAL(3, 2),             -- e.g., 4.50
    skills_set TEXT[],                           -- Array of strings: {'React', 'Python'}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for performance
CREATE INDEX idx_team_name ON employees(team_name);
CREATE INDEX idx_employee_num ON employees(employee_number);