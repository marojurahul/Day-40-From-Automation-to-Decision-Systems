-- Drop existing tables if they exist (safe to run even if not created yet)
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS reps;
DROP TABLE IF EXISTS deals;

-- Create Reps Table
CREATE TABLE reps (
    rep_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    region TEXT
);

-- Create Activities Table
CREATE TABLE activities (
    date DATE,
    rep_id INTEGER REFERENCES reps(rep_id),
    calls INTEGER,
    demos INTEGER,
    follow_ups INTEGER
);

-- Create Deals Table
CREATE TABLE deals (
    deal_id TEXT PRIMARY KEY,
    rep_id INTEGER REFERENCES reps(rep_id),
    value INTEGER,
    stage TEXT,
    close_date DATE
);

-- Insert Sample Data (Copy-Paste from your Excel)
INSERT INTO reps (rep_id, name, region) VALUES
(1, 'Priya', 'North'),
(2, 'Rohan', 'South'),
(3, 'Arjun', 'West');

INSERT INTO activities (date, rep_id, calls, demos, follow_ups) VALUES
('2026-01-05', 1, 12, 3, 8),
('2026-01-05', 2, 5, 1, 2),
('2026-01-05', 3, 9, 2, 6),
('2026-01-06', 1, 10, 2, 7),
('2026-01-06', 2, 3, 0, 1),
('2026-01-06', 3, 8, 3, 5),
('2026-01-07', 1, 15, 4, 10),
('2026-01-07', 2, 4, 0, 0),
('2026-01-07', 3, 11, 3, 8);

INSERT INTO deals (deal_id, rep_id, value, stage, close_date) VALUES
('D101', 1, 50000, 'Closed Won', '2026-01-04'),
('D102', 2, 30000, 'Proposal', NULL),
('D103', 1, 75000, 'Negotiation', NULL),
('D104', 3, 45000, 'Qualified', NULL);

SELECT 
    r.name AS rep_name,
    r.region,
    SUM(a.calls) AS total_calls,
    SUM(a.demos) AS total_demos,
    SUM(a.follow_ups) AS total_followups,
    COUNT(d.deal_id) AS deals_closed,
    COALESCE(SUM(d.value), 0) AS total_value
FROM reps r
JOIN activities a ON r.rep_id = a.rep_id
LEFT JOIN deals d ON r.rep_id = d.rep_id AND d.stage = 'Closed Won'
WHERE a.date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY r.rep_id, r.name, r.region
ORDER BY total_demos DESC;

WITH weekly_stats AS (
    SELECT 
        rep_id,
        SUM(demos) AS total_demos,
        COUNT(*) AS days_active
    FROM activities
    WHERE date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY rep_id
),
avg_demos AS (
    SELECT AVG(total_demos) AS avg_demo_count
    FROM weekly_stats
)
SELECT 
    r.name AS rep_name,
    ws.total_demos,
    ROUND(ws.total_demos * 100.0 / ad.avg_demo_count, 0) || '%' AS performance_pct,
    CASE 
        WHEN ws.total_demos < ad.avg_demo_count * 0.7 THEN '⚠️ At Risk'
        ELSE '✅ Healthy'
    END AS status
FROM weekly_stats ws
JOIN reps r ON ws.rep_id = r.rep_id
CROSS JOIN avg_demos ad
WHERE ws.total_demos < ad.avg_demo_count * 0.7
ORDER BY ws.total_demos ASC;


SELECT 
    stage,
    COUNT(*) AS deal_count,
    SUM(value) AS total_value
FROM deals
GROUP BY stage
ORDER BY 
    CASE stage
        WHEN 'Qualified' THEN 1
        WHEN 'Proposal' THEN 2
        WHEN 'Negotiation' THEN 3
        WHEN 'Closed Won' THEN 4
        ELSE 5
    END;


	CREATE OR REPLACE VIEW rep_performance_view AS
SELECT 
    r.name AS rep_name,
    r.region,
    SUM(a.calls) AS total_calls,
    SUM(a.demos) AS total_demos,
    SUM(a.follow_ups) AS total_followups,
    COUNT(d.deal_id) AS deals_closed,
    COALESCE(SUM(d.value), 0) AS total_value,
    CASE 
        WHEN SUM(a.demos) < (SELECT AVG(total_demos) FROM (
            SELECT rep_id, SUM(demos) AS total_demos
            FROM activities
            WHERE date >= CURRENT_DATE - INTERVAL '7 days'
            GROUP BY rep_id
        ) AS avg_data) * 0.7 THEN '⚠️ At Risk'
        ELSE '✅ Healthy'
    END AS status
FROM reps r
JOIN activities a ON r.rep_id = a.rep_id
LEFT JOIN deals d ON r.rep_id = d.rep_id AND d.stage = 'Closed Won'
WHERE a.date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY r.rep_id, r.name, r.region;



SELECT inet_server_addr();
