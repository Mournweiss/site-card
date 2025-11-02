-- Database schema and initial/seed data for SiteCard app
-- Tables: avatars, about, careers, skill_groups, skills, experiences, portfolios, portfolio_languages, portfolio_tech_badges, contacts, authorized_bot_users

-- Avatar: business-card info, profile picture
CREATE TABLE IF NOT EXISTS avatars (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128),
    role VARCHAR(128),
    description TEXT,
    image_ext VARCHAR(8)
);
-- Demo seed data for avatars
INSERT INTO avatars (id, name, role, description, image_ext) VALUES
    (1, 'Anton Chekhov', 'Fullstack developer', 'Vivamus, moriendum est. Non scholae, sed vitae discimus. Tempora mutantur, nos et mutamur in illis. Carpe diem, quam minimum credula postero. Audaces fortuna iuvat. Cogito, ergo sum.', NULL)
ON CONFLICT (id) DO NOTHING;

-- About: general profile metadata
CREATE TABLE IF NOT EXISTS about (
    id SERIAL PRIMARY KEY,
    age INTEGER,
    location VARCHAR(128),
    education VARCHAR(128),
    languages TEXT
);
-- Demo seed for user meta
INSERT INTO about (id, age, location, education, languages)
VALUES (1, 29, 'Moscow', 'MSTU Bauman', 'English (C1), Russian (native)')
ON CONFLICT (id) DO NOTHING;

-- Careers: work experience (references about)
CREATE TABLE IF NOT EXISTS careers (
    id SERIAL PRIMARY KEY,
    about_id INTEGER REFERENCES about(id) ON DELETE CASCADE, -- soft-link for CV
    company VARCHAR(128),
    position VARCHAR(128),
    start_date VARCHAR(32),
    end_date VARCHAR(32)
);
-- Demo seed for career history
INSERT INTO careers (about_id, company, position, start_date, end_date) VALUES
    (1, 'Acme Corp', 'Senior Developer', '2018', '2022'),
    (1, 'AcmeX', 'Lead Developer', '2022', 'present')
ON CONFLICT DO NOTHING;

-- Skill groups: main categories
CREATE TABLE IF NOT EXISTS skill_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64)
);

-- Skills per group (color for frontend, level for pie chart)
CREATE TABLE IF NOT EXISTS skills (
    id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES skill_groups(id) ON DELETE CASCADE, -- Many-to-one
    name VARCHAR(64),
    level INTEGER DEFAULT 0, -- score for chart
    color VARCHAR(16)
);

-- Demo seed skill groups
INSERT INTO skill_groups (id, name) VALUES
    (1, 'Languages'),
    (2, 'Tools/Tech'),
    (3, 'Operating Systems')
ON CONFLICT (id) DO NOTHING;
-- Demo seed skills
INSERT INTO skills (group_id, name, level, color) VALUES
    (1, 'Ruby', 8, '#701516'),
    (1, 'JavaScript', 7, '#f1e05a'),
    (1, 'Python', 6, '#3572a5'),
    (2, 'Docker', 7, '#f1502f'),
    (2, 'Kubernetes', 6, '#563d7c'),
    (2, 'Webpack', 8, '#8ed6fb'),
    (2, 'Vite', 5, '#fbab1d'),
    (3, 'Linux', 9, '#1793d1'),
    (3, 'Windows', 8, '#00adef'),
    (3, 'macOS', 7, '#999999'),
    (3, 'BSD', 5, '#e6002e'),
    (3, 'Unix', 6, '#92b300'),
    (3, 'Android', 7, '#a4c639'),
    (3, 'iOS', 6, '#5fc9f8')
ON CONFLICT DO NOTHING;

-- Experiences: for radar chart/skill matrix
CREATE TABLE IF NOT EXISTS experiences (
    id SERIAL PRIMARY KEY,
    label VARCHAR(64), -- field name
    value INTEGER
);
-- Demo seed experience values
INSERT INTO experiences (label, value) VALUES
('Frontend', 95),
('Backend', 78),
('DevOps', 60),
('Mobile', 30),
('Data Science', 40),
('UI/UX', 83),
('Project Mgmt.', 69)
ON CONFLICT DO NOTHING;

-- Portfolios: key projects
CREATE TABLE IF NOT EXISTS portfolios (
    id SERIAL PRIMARY KEY,
    title VARCHAR(128),
    description TEXT,
    url TEXT NOT NULL, -- project/code/demo link
    order_index INTEGER DEFAULT 0
);

-- Languages used per portfolio (percent for bar, color for legend)
CREATE TABLE IF NOT EXISTS portfolio_languages (
    id SERIAL PRIMARY KEY,
    portfolio_id INTEGER REFERENCES portfolios (id) ON DELETE CASCADE,
    name VARCHAR(64),
    percent INTEGER,
    color VARCHAR(16),
    order_index INTEGER DEFAULT 0
);

-- Tech badges (icons/chips per project)
CREATE TABLE IF NOT EXISTS portfolio_tech_badges (
    id SERIAL PRIMARY KEY,
    portfolio_id INTEGER REFERENCES portfolios (id) ON DELETE CASCADE,
    name VARCHAR(64),
    icon VARCHAR(64) -- CSS/svg icon ref
);

-- Demo seed up to 3 major portfolio items
INSERT INTO portfolios (id, title, description, url, order_index) VALUES
(1, 'AI SaaS Platform', 'Carpe diem. Qui non proficit, deficit. Scientia potentia est. Ars longa, vita brevis. Fortes fortuna adiuvat. Experientia docet. Non solum nobis nati sumus. Laborare est orare. Docendo discimus. Nemo solus satis sapit.', 'https://github.com/example/ai-saas-platform', 0),
(2, 'DevOps Dashboard', 'Audentes fortuna iuvat. Acta, non verba. Per aspera ad astra. Nil desperandum. Festina lente. Mens sana in corpore sano. Malum consilium est quod mutari non potest. Age quod agis. Virtutis fortuna comes. Discere est vivere.', 'https://github.com/example/devops-dashboard', 1),
(3, 'Smart CRM', 'Alea iacta est. Dura lex, sed lex. Verba volant, scripta manent. Non progredi est regredi. Tempus fugit. Faber est suae quisque fortunae. Consuetudo est altera natura. In vino veritas. Barba non facit philosophum. Qui quaerit, invenit.', 'https://github.com/example/smart-crm', 2)
ON CONFLICT (id) DO NOTHING;

-- Portfolio language composition per project
INSERT INTO portfolio_languages (portfolio_id, name, percent, color, order_index) VALUES
(1, 'Python', 58, '#3572a5', 0), (1, 'Ruby', 32, '#701516', 1), (1, 'JavaScript', 10, '#f1e05a', 2),
(2, 'Go', 40, '#1290B1', 0), (2, 'Rust', 38, '#CD8B6F', 1), (2, 'Dockerfile', 22, '#334348', 2),
(3, 'Ruby', 48, '#701516', 0), (3, 'TypeScript', 35, '#2b7489', 1), (3, 'Shell', 17, '#76BA47', 2)
ON CONFLICT DO NOTHING;

-- Portfolio-related tech badge (svg/icon/label)
INSERT INTO portfolio_tech_badges (portfolio_id, name, icon) VALUES
(1, 'PyTorch', 'bi-cpu'), (1, 'AWS', 'bi-cloud'), (1, 'Docker', 'bi-box'), (1, 'FastAPI', 'bi-git'),
(2, 'Prometheus', 'bi-stack'), (2, 'Grafana', 'bi-graph-up'), (2, 'CI/CD', 'bi-tools'), (2, 'NGINX', 'bi-terminal'),
(3, 'Twilio', 'bi-telephone'), (3, 'OAuth', 'bi-people'), (3, 'Sidekiq', 'bi-bar-chart')
ON CONFLICT DO NOTHING;

-- Contacts table: site owner's contact methods (with icon/label)
CREATE TABLE IF NOT EXISTS contacts (
    id SERIAL PRIMARY KEY,
    type VARCHAR(32),
    value VARCHAR(128),
    label VARCHAR(64),
    icon VARCHAR(64)
);
-- Demo contact methods
INSERT INTO contacts (type, value, label, icon) VALUES
('telegram', 'https://t.me/example', 'Telegram', 'bi-telegram'),
('github', 'https://github.com/example', 'GitHub', 'bi-github'),
('email', 'anton.chekhov@example.com', 'E-mail', 'bi-envelope')
ON CONFLICT DO NOTHING;

-- List of Telegram WebApp users authorized for notifications
CREATE TABLE IF NOT EXISTS authorized_bot_users (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE, -- Telegram user ID
    username VARCHAR(64),
    authorized_at TIMESTAMP DEFAULT NOW()
);
