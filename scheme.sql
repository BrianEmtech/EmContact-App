-- Django auth user (use django.contrib.auth_user)
-- auth_user(id, username, password, email, is_active, ...)

CREATE TABLE role (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) UNIQUE NOT NULL,  -- "HR Manager", "Employee"
    description     TEXT
);

CREATE TABLE permission (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(100) UNIQUE NOT NULL,  -- e.g. "view_employee_all"
    description     TEXT
);

CREATE TABLE role_permission (
    id              SERIAL PRIMARY KEY,
    role_id         INT NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    permission_id   INT NOT NULL REFERENCES permission(id) ON DELETE CASCADE,
    UNIQUE (role_id, permission_id)
);

CREATE TABLE employee (
    id                  SERIAL PRIMARY KEY,
    user_id             INT UNIQUE REFERENCES auth_user(id) ON DELETE SET NULL,
    employee_code       VARCHAR(50) UNIQUE NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    other_names         VARCHAR(100),
    gender              VARCHAR(20),
    marital_status      VARCHAR(20),
    date_of_birth       DATE,
    national_id_number  VARCHAR(50),
    tin_number          VARCHAR(50),       -- URA TIN
    nssf_number         VARCHAR(50),
    email_official      VARCHAR(150),
    phone_primary       VARCHAR(30),
    phone_secondary     VARCHAR(30),
    address_current     TEXT,
    address_permanent   TEXT,
    hire_date           DATE NOT NULL,
    employment_type     VARCHAR(50),       -- permanent, contract, intern
    status              VARCHAR(30) DEFAULT 'active', -- active, suspended, exited
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE department (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) UNIQUE NOT NULL,
    code        VARCHAR(50) UNIQUE,
    parent_id   INT REFERENCES department(id) ON DELETE SET NULL
);

CREATE TABLE position (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(150) NOT NULL,
    description     TEXT,
    level           INT,               -- 1=junior ... N=exec, used for peer/manager rules
    is_managerial   BOOLEAN DEFAULT FALSE
);

CREATE TABLE employment (
    id              SERIAL PRIMARY KEY,
    employee_id     INT NOT NULL REFERENCES employee(id) ON DELETE CASCADE,
    department_id   INT NOT NULL REFERENCES department(id),
    position_id     INT NOT NULL REFERENCES position(id),
    supervisor_id   INT REFERENCES employee(id),  -- direct manager
    start_date      DATE NOT NULL,
    end_date        DATE,
    base_salary     NUMERIC(14,2),
    currency        VARCHAR(10) DEFAULT 'UGX',
    work_location   VARCHAR(150),
    is_primary      BOOLEAN DEFAULT TRUE,
    UNIQUE (employee_id, is_primary)
);


CREATE TABLE attendance_record (
    id              SERIAL PRIMARY KEY,
    employee_id     INT NOT NULL REFERENCES employee(id) ON DELETE CASCADE,
    work_date       DATE NOT NULL,
    check_in_time   TIMESTAMP,
    check_out_time  TIMESTAMP,
    source          VARCHAR(50),          -- biometric, web, manual
    status          VARCHAR(30),          -- present, absent, remote, on_leave
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (employee_id, work_date)
);

CREATE TABLE leave_type (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,    -- annual, sick, maternity
    code            VARCHAR(50) UNIQUE,
    is_paid         BOOLEAN DEFAULT TRUE,
    annual_days     INT
);

CREATE TABLE leave_request (
    id                  SERIAL PRIMARY KEY,
    employee_id         INT NOT NULL REFERENCES employee(id) ON DELETE CASCADE,
    leave_type_id       INT NOT NULL REFERENCES leave_type(id),
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    reason              TEXT,
    status              VARCHAR(30) DEFAULT 'pending', -- pending, approved, rejected, cancelled
    approver_id         INT REFERENCES employee(id),
    decided_at          TIMESTAMP,
    created_at          TIMESTAMP DEFAULT NOW()
);



CREATE TABLE pay_period (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50),          -- "Jan 2026"
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    is_closed       BOOLEAN DEFAULT FALSE,
    UNIQUE (start_date, end_date)
);

CREATE TABLE pay_component_type (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,   -- Basic Salary, Housing, PAYE, NSSF
    code            VARCHAR(50) UNIQUE,
    category        VARCHAR(30),            -- earning, deduction, tax, benefit
    is_taxable      BOOLEAN DEFAULT TRUE,
    affects_nssf    BOOLEAN DEFAULT FALSE
);

CREATE TABLE tax_rule (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    country         VARCHAR(50) DEFAULT 'UG',
    min_amount      NUMERIC(14,2),
    max_amount      NUMERIC(14,2),
    rate_percent    NUMERIC(5,2),           -- for URA brackets
    fixed_amount    NUMERIC(14,2) DEFAULT 0
);

CREATE TABLE payroll_run (
    id              SERIAL PRIMARY KEY,
    pay_period_id   INT NOT NULL REFERENCES pay_period(id),
    run_date        TIMESTAMP DEFAULT NOW(),
    status          VARCHAR(30) DEFAULT 'draft' -- draft, confirmed, posted
);

CREATE TABLE payslip (
    id              SERIAL PRIMARY KEY,
    payroll_run_id  INT NOT NULL REFERENCES payroll_run(id) ON DELETE CASCADE,
    employee_id     INT NOT NULL REFERENCES employee(id),
    gross_pay       NUMERIC(14,2) NOT NULL,
    total_deductions NUMERIC(14,2) NOT NULL,
    net_pay         NUMERIC(14,2) NOT NULL,
    currency        VARCHAR(10) DEFAULT 'UGX',
    generated_at    TIMESTAMP DEFAULT NOW(),
    UNIQUE (payroll_run_id, employee_id)
);

CREATE TABLE payslip_line (
    id                  SERIAL PRIMARY KEY,
    payslip_id          INT NOT NULL REFERENCES payslip(id) ON DELETE CASCADE,
    pay_component_type_id INT NOT NULL REFERENCES pay_component_type(id),
    amount              NUMERIC(14,2) NOT NULL,
    is_manual           BOOLEAN DEFAULT FALSE
);



CREATE TABLE policy_category (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE policy_document (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    category_id     INT REFERENCES policy_category(id),
    version         VARCHAR(50),
    effective_date  DATE,
    file_url        TEXT,          -- or Django FileField
    is_active       BOOLEAN DEFAULT TRUE,
    created_by_id   INT REFERENCES employee(id),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE training_program (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    category        VARCHAR(100),
    provider        VARCHAR(150),
    start_date      DATE,
    end_date        DATE,
    is_mandatory    BOOLEAN DEFAULT FALSE
);

CREATE TABLE employee_training (
    id                  SERIAL PRIMARY KEY,
    employee_id         INT NOT NULL REFERENCES employee(id) ON DELETE CASCADE,
    training_program_id INT NOT NULL REFERENCES training_program(id),
    status              VARCHAR(30) DEFAULT 'assigned', -- assigned, in_progress, completed, failed
    score               NUMERIC(5,2),
    completed_at        TIMESTAMP,
    UNIQUE (employee_id, training_program_id)
);

CREATE TABLE mentorship (
    id              SERIAL PRIMARY KEY,
    mentor_id       INT NOT NULL REFERENCES employee(id),
    mentee_id       INT NOT NULL REFERENCES employee(id),
    start_date      DATE NOT NULL,
    end_date        DATE,
    goals           TEXT,
    status          VARCHAR(30) DEFAULT 'active',
    UNIQUE (mentor_id, mentee_id, start_date)
);



CREATE TABLE goal (
    id              SERIAL PRIMARY KEY,
    employee_id     INT NOT NULL REFERENCES employee(id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    weight          NUMERIC(5,2),     -- % contribution
    start_date      DATE,
    end_date        DATE,
    created_by_id   INT REFERENCES employee(id),
    alignment_level VARCHAR(50)       -- individual, team, org
);

CREATE TABLE work_task (
    id              SERIAL PRIMARY KEY,
    assigned_to_id  INT NOT NULL REFERENCES employee(id),
    created_by_id   INT REFERENCES employee(id),
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    status          VARCHAR(30) DEFAULT 'open', -- open, in_progress, done, cancelled
    due_date        DATE,
    completed_at    TIMESTAMP,
    goal_id         INT REFERENCES goal(id)
);

CREATE TABLE performance_cycle (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,   -- "2026 H1"
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    is_closed       BOOLEAN DEFAULT FALSE
);

CREATE TABLE performance_review (
    id                  SERIAL PRIMARY KEY,
    employee_id         INT NOT NULL REFERENCES employee(id),
    reviewer_id         INT NOT NULL REFERENCES employee(id),
    performance_cycle_id INT NOT NULL REFERENCES performance_cycle(id),
    overall_rating      NUMERIC(3,2),
    comments            TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    UNIQUE (employee_id, reviewer_id, performance_cycle_id)
);

CREATE TABLE performance_metric (
    id                  SERIAL PRIMARY KEY,
    employee_id         INT NOT NULL REFERENCES employee(id),
    performance_cycle_id INT NOT NULL REFERENCES performance_cycle(id),
    metric_name         VARCHAR(100) NOT NULL,  -- e.g. "tasks_completed_on_time"
    metric_value        NUMERIC(14,4) NOT NULL,
    created_at          TIMESTAMP DEFAULT NOW(),
    UNIQUE (employee_id, performance_cycle_id, metric_name)
);
