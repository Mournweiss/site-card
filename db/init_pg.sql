CREATE TABLE IF NOT EXISTS about (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128),
    age INTEGER,
    location VARCHAR(128),
    education VARCHAR(128),
    role VARCHAR(128),
    languages TEXT,
    description TEXT
);

INSERT INTO about (id, name, age, location, education, role, languages, description)
VALUES (1, 'John Doe', 29, 'Moscow', 'MSTU Bauman', 'Web developer', 'English (C1), Russian (native)', 'Experienced web developer specializing in fullstack solutions.')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS careers (
    id SERIAL PRIMARY KEY,
    about_id INTEGER REFERENCES about(id) ON DELETE CASCADE,
    company VARCHAR(128),
    position VARCHAR(128),
    start_date VARCHAR(32),
    end_date VARCHAR(32)
);
INSERT INTO careers (about_id, company, position, start_date, end_date) VALUES
    (1, 'Acme Corp', 'Senior Developer', '2018', '2022'),
    (1, 'AcmeX', 'Lead Developer', '2022', 'present')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS skill_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64)
);

CREATE TABLE IF NOT EXISTS skills (
    id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES skill_groups(id) ON DELETE CASCADE,
    name VARCHAR(64),
    level INTEGER DEFAULT 0,
    color VARCHAR(16)
);

INSERT INTO skill_groups (id, name) VALUES
    (1, 'Languages'),
    (2, 'Tools/Tech'),
    (3, 'DevOps')
ON CONFLICT (id) DO NOTHING;

INSERT INTO skills (group_id, name, level, color) VALUES
    (1, 'Ruby', 8, '#701516'),
    (1, 'JavaScript', 7, '#f1e05a'),
    (1, 'Python', 6, '#3572a5'),
    (2, 'Docker', 7, '#f1502f'),
    (2, 'Kubernetes', 6, '#563d7c'),
    (2, 'Webpack', 8, '#8ed6fb'),
    (2, 'Vite', 5, '#fbab1d'),
    (3, 'CI/CD', 8, '#4485FE'),
    (3, 'K8s Ops', 6, '#32DCB8'),
    (3, 'Monitoring', 5, '#2396ED')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS experiences (
    id SERIAL PRIMARY KEY,
    label VARCHAR(64),
    value INTEGER
);
INSERT INTO experiences (label, value) VALUES
('Frontend', 95),
('Backend', 78),
('DevOps', 60),
('Mobile', 30),
('Data Science', 40),
('UI/UX', 83),
('Project Mgmt.', 69)
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS portfolios (
    id SERIAL PRIMARY KEY,
    title VARCHAR(128),
    description TEXT,
    image VARCHAR(256),
    order_index INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS portfolio_languages (
    id SERIAL PRIMARY KEY,
    portfolio_id INTEGER REFERENCES portfolios (id) ON DELETE CASCADE,
    name VARCHAR(64),
    percent INTEGER,
    color VARCHAR(16),
    order_index INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS portfolio_tech_badges (
    id SERIAL PRIMARY KEY,
    portfolio_id INTEGER REFERENCES portfolios (id) ON DELETE CASCADE,
    name VARCHAR(64),
    icon VARCHAR(64)
);

INSERT INTO portfolios (id, title, description, image, order_index) VALUES
(1, 'AI SaaS Platform', 'End-to-end SaaS solution with ML pipeline, robust API, and HA cloud deployment. Integrated with Stripe, OpenAI, and custom analytics.', '/static/portfolio1.jpg', 0),
(2, 'DevOps Dashboard', 'Realtime server analytics, live container scaling charts, and full Kubernetes workload automation with Prometheus and Grafana integration.', '/static/portfolio2.jpg', 1),
(3, 'Smart CRM', 'Multi-tenant CRM, live chat, advanced analytics, role-based controls, social media and telephony integration for massive business user base.', '/static/portfolio3.jpg', 2)
ON CONFLICT (id) DO NOTHING;

INSERT INTO portfolio_languages (portfolio_id, name, percent, color, order_index) VALUES
(1, 'Python', 58, '#3572a5', 0), (1, 'Ruby', 32, '#701516', 1), (1, 'JavaScript', 10, '#f1e05a', 2),
(2, 'Kubernetes YML', 40, '#563d7c', 0), (2, 'React', 38, '#61dbfb', 1), (2, 'Dockerfile', 22, '#f1502f', 2),
(3, 'Ruby', 48, '#701516', 0), (3, 'TypeScript', 35, '#2b7489', 1), (3, 'Vue.js', 17, '#42a5f5', 2)
ON CONFLICT DO NOTHING;

INSERT INTO portfolio_tech_badges (portfolio_id, name, icon) VALUES
(1, 'PyTorch', 'bi-cpu'), (1, 'AWS', 'bi-cloud'), (1, 'Docker', 'bi-box'), (1, 'FastAPI', 'bi-git'),
(2, 'Prometheus', 'bi-stack'), (2, 'Grafana', 'bi-graph-up'), (2, 'CI/CD', 'bi-tools'), (2, 'NGINX', 'bi-terminal'),
(3, 'Twilio', 'bi-telephone'), (3, 'OAuth', 'bi-people'), (3, 'Sidekiq', 'bi-bar-chart')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS contacts (
    id SERIAL PRIMARY KEY,
    type VARCHAR(32),
    value VARCHAR(128),
    label VARCHAR(64),
    icon VARCHAR(64)
);

INSERT INTO contacts (type, value, label, icon) VALUES
('telegram', 'https://t.me/yourusername', 'Telegram', 'bi-telegram'),
('github', 'https://github.com/yourusername', 'GitHub', 'bi-github'),
('email', 'john.doe@example.com', 'E-mail', 'bi-envelope')
ON CONFLICT DO NOTHING;
