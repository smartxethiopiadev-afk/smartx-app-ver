-- =====================================================================
-- SMART X ETHIOPIAN LEARNING ACADEMY - ALL-IN-ONE SUPABASE SCHEMA
-- Contains:
-- 1. student_credentials (Admin-issued credentials & single-device hardware lock)
-- 2. packages (Single Subject, Grade Streams, Matric Prep)
-- 3. user_subscriptions (Subscriptions & device binding)
-- 4. activation_codes (One-time codes with device binding)
-- 5. short_notes (Comprehensive unit summaries & key takeaways)
-- 6. worksheets (Step-by-step solutions & practice problems)
-- 7. subjects, units, questions, question_options (Full curriculum quiz engine)
-- 8. videos (YouTube masterclasses & curriculum playlists)
-- 9. Row Level Security (RLS) policies for secure student access
-- =====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------
-- 1. PACKAGES TABLE
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.packages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    grade INTEGER NOT NULL,
    price_etb NUMERIC(10, 2) NOT NULL,
    description TEXT NOT NULL,
    badge_text TEXT,
    tier TEXT DEFAULT 'stream_or_grade', -- 'single_subject', 'stream_or_grade', 'all_inclusive'
    subject TEXT,
    features JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 2. STUDENT CREDENTIALS TABLE (Admin-Issued Login & Device Lock)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    package_id TEXT REFERENCES public.packages(id) ON DELETE SET NULL,
    device_id TEXT, -- Locked to first device on login (e.g. AND_9F82A31B)
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 3. USER SUBSCRIPTIONS & SINGLE-DEVICE BINDING
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    package_id TEXT NOT NULL,
    device_id TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_phone_package UNIQUE(phone_number, package_id)
);

-- ---------------------------------------------------------------------
-- 4. ACTIVATION CODES TABLE
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activation_codes (
    code TEXT PRIMARY KEY,
    package_id TEXT NOT NULL,
    grade INT NOT NULL,
    subject TEXT,
    is_used BOOLEAN DEFAULT false,
    used_by_phone TEXT,
    used_by_device TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 5. SHORT NOTES TABLE (Unit Summaries & Formula Sheets)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.short_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INTEGER NOT NULL,
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    page_number INTEGER DEFAULT 1,
    order_index INTEGER DEFAULT 1,
    key_takeaways JSONB DEFAULT '[]'::jsonb,
    formulas JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 6. WORKSHEETS TABLE (Step-by-step problem sets and solutions)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.worksheets (
    id TEXT PRIMARY KEY,
    grade INTEGER NOT NULL,
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    questions_html TEXT NOT NULL,
    solutions_html TEXT NOT NULL,
    package_id TEXT REFERENCES public.packages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 7. CURRICULUM QUIZ STRUCTURE (Subjects, Units, Questions & Options)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subjects (
    id TEXT PRIMARY KEY, -- e.g. '12_mathematics', '12_physics'
    name TEXT NOT NULL,
    grade INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.units (
    id TEXT PRIMARY KEY, -- e.g. '12_mathematics_1'
    subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id TEXT NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_number INTEGER NOT NULL,
    order_index INTEGER DEFAULT 1,
    explanation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.question_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false NOT NULL,
    explanation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 8. VIDEOS TABLE (Masterclasses & Video Playlists with Part Numbers)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INT NOT NULL,
    subject TEXT NOT NULL,
    unit_number INT NOT NULL,
    part_number INT DEFAULT 1, -- Part division (e.g. Part 1, Part 2, Part 3)
    title TEXT NOT NULL,
    youtube_video_id TEXT NOT NULL,
    duration_text TEXT,
    order_index INT DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 9. STUDENT REGISTRATIONS & OFFLINE-READY DEVICE PROFILES
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    school_name TEXT,
    gender TEXT,
    grade INTEGER NOT NULL,
    device_id TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT UNIQUE,
    full_name TEXT,
    grade INTEGER,
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- ---------------------------------------------------------------------
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.short_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worksheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow public read access to curriculum tables & packages
DROP POLICY IF EXISTS "Public Read Packages" ON public.packages;
CREATE POLICY "Public Read Packages" ON public.packages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Short Notes" ON public.short_notes;
CREATE POLICY "Public Read Short Notes" ON public.short_notes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Worksheets" ON public.worksheets;
CREATE POLICY "Public Read Worksheets" ON public.worksheets FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Subjects" ON public.subjects;
CREATE POLICY "Public Read Subjects" ON public.subjects FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Units" ON public.units;
CREATE POLICY "Public Read Units" ON public.units FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Questions" ON public.questions;
CREATE POLICY "Public Read Questions" ON public.questions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Question Options" ON public.question_options;
CREATE POLICY "Public Read Question Options" ON public.question_options FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Videos" ON public.videos;
CREATE POLICY "Public Read Videos" ON public.videos FOR SELECT USING (true);

-- Allow student authentication & single device binding
DROP POLICY IF EXISTS "Public Read Student Credentials" ON public.student_credentials;
CREATE POLICY "Public Read Student Credentials" ON public.student_credentials FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Update Student Credentials Device" ON public.student_credentials;
CREATE POLICY "Public Update Student Credentials Device" ON public.student_credentials FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Subscriptions Access" ON public.user_subscriptions;
CREATE POLICY "Public Subscriptions Access" ON public.user_subscriptions FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Activation Codes Access" ON public.activation_codes;
CREATE POLICY "Public Activation Codes Access" ON public.activation_codes FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Profiles Access" ON public.profiles;
CREATE POLICY "Public Profiles Access" ON public.profiles FOR ALL USING (true);

-- ---------------------------------------------------------------------
-- 11. SEED DATA - PACKAGES
-- ---------------------------------------------------------------------
INSERT INTO public.packages (id, title, grade, price_etb, description, badge_text, tier, subject, features)
VALUES
    ('pkg_g12_mathematics', 'Grade 12 Mathematics Only', 12, 150.00, 'Complete Units 1–10 access for Grade 12 Mathematics. Full chapter notes, formula sheets, and step-by-step worksheets.', 'FOCUSED', 'single_subject', 'Mathematics', '["Full Grade 12 Math Units (1–10)", "Calculus & Vector Formulas", "Practice Worksheets & Solutions", "Single-Phone Offline Download"]'::jsonb),
    ('pkg_g12_physics', 'Grade 12 Physics Only', 12, 150.00, 'Complete Units 1–8 access for Grade 12 Physics. Full mechanics, wave & optics notes and worksheets.', 'FOCUSED', 'single_subject', 'Physics', '["Full Grade 12 Physics Units", "Formulas & Derivations", "Practice Worksheets & Solutions", "Single-Phone Offline Download"]'::jsonb),
    ('pkg_grade_9', 'Grade 9 Foundation All-Subjects Pack', 9, 400.00, 'Complete access to all Grade 9 curriculum subjects (Math, Physics, Chemistry, Biology, English).', 'MOST POPULAR', 'stream_or_grade', NULL, '["All Grade 9 Subjects & Units", "Curriculum Short Notes", "Chapter Quizzes & Worksheets", "100% Offline Single Device"]'::jsonb),
    ('pkg_grade_10', 'Grade 10 National Exam (EGSECE) Booster', 10, 400.00, 'Complete Grade 10 curriculum with EGSECE model tests, formula sheets, and full unit worksheets.', 'EXAM READY', 'stream_or_grade', NULL, '["All Grade 10 Subjects Unlocked", "Solved Model Exams", "EGSECE Question Bank", "100% Offline Single Device"]'::jsonb),
    ('pkg_grade_11', 'Grade 11 Natural & Social Sciences Mastery', 11, 400.00, 'Full Grade 11 preparatory package covering all subjects with advanced practice problem sets.', 'PREP PACK', 'stream_or_grade', NULL, '["All Grade 11 Subjects Unlocked", "Advanced Problem Worksheets", "Step-by-step Solutions", "100% Offline Single Device"]'::jsonb),
    ('pkg_grade_12', 'Grade 12 Natural & Social Sciences All-Pack', 12, 400.00, 'Full Grade 12 curriculum package covering all subjects, short notes, quizzes, and unit worksheets.', 'ALL SUBJECTS', 'stream_or_grade', NULL, '["All Grade 12 Subjects Unlocked", "Complete Curriculum Notes", "All Unit Worksheets", "100% Offline Single Device"]'::jsonb),
    ('pkg_all_inclusive_g12', 'Grade 12 University Entrance (EUEE) Master Package', 12, 600.00, 'Ultimate preparation bundle: All Grade 12 subjects + 10 Years Past Matric Exams Solved + Formula Cheat Sheets + Priority Telegram Tutor Support.', 'BEST VALUE', 'all_inclusive', NULL, '["Everything in All-Subjects Pack", "10+ Years Past EUEE Questions Solved", "Formula Flashcards & Cheat Sheets", "VIP Admin & Telegram Support", "Single-Device Anti-Loss Sync"]'::jsonb)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    price_etb = EXCLUDED.price_etb,
    description = EXCLUDED.description,
    badge_text = EXCLUDED.badge_text,
    tier = EXCLUDED.tier,
    subject = EXCLUDED.subject,
    features = EXCLUDED.features;

-- ---------------------------------------------------------------------
-- 12. SEED DATA - SAMPLE ADMIN-ISSUED CREDENTIALS (For Demo & Testing)
-- ---------------------------------------------------------------------
INSERT INTO public.student_credentials (full_name, phone_number, password, package_id, is_active)
VALUES
    ('Habtamu Yifiru', '0978254242', 'smartx2026', 'pkg_all_inclusive_g12', true),
    ('Abebe Bikila', '0911223344', 'abebe123', 'pkg_grade_12', true),
    ('Tirunesh Dibaba', '0922334455', 'tiru2026', 'pkg_grade_11', true),
    ('Kenenisa Bekele', '0933445566', 'ken2026', 'pkg_grade_10', true),
    ('Derartu Tulu', '0944556677', 'derartu99', 'pkg_grade_9', true)
ON CONFLICT (phone_number) DO NOTHING;

-- ---------------------------------------------------------------------
-- 13. SEED DATA - SHORT NOTES SAMPLES
-- ---------------------------------------------------------------------
INSERT INTO public.short_notes (grade, subject, unit_number, title, content, page_number, order_index, key_takeaways, formulas)
VALUES
    (12, 'Mathematics', 1, 'Sequences and Series Summary', 
    '<h3>Unit 1: Sequences and Series</h3><p>A <strong>sequence</strong> is a function whose domain is the set of positive integers. An <strong>arithmetic sequence (AP)</strong> is a sequence where the difference between consecutive terms is constant ($d = a_{n} - a_{n-1}$).</p><p>A <strong>geometric sequence (GP)</strong> has a constant ratio ($r = \frac{a_n}{a_{n-1}}$).</p><h4>Sum of Infinite Geometric Series</h4><p>An infinite geometric series converges if and only if $|r| < 1$. In that case, $S_\infty = \frac{a_1}{1 - r}$.</p>', 
    1, 1, '["An AP has constant common difference d.", "A GP has constant common ratio r.", "Infinite GP converges when |r| < 1."]'::jsonb, '["a_n = a_1 + (n - 1)d", "S_n = \\frac{n}{2}[2a_1 + (n - 1)d]", "a_n = a_1 \\cdot r^{n-1}", "S_\\infty = \\frac{a_1}{1 - r}"]'::jsonb),
    
    (12, 'Physics', 1, 'Thermodynamics & Heat Engines', 
    '<h3>Unit 1: Thermodynamics</h3><p>Thermodynamics deals with heat, work, and temperature. The <strong>First Law of Thermodynamics</strong> is the law of conservation of energy: $\Delta U = Q - W$.</p><p>The <strong>Second Law of Thermodynamics</strong> states that total entropy of an isolated system always increases over time. The maximum efficiency of a heat engine is given by the Carnot efficiency: $\eta_{max} = 1 - \frac{T_C}{T_H}$.</p>', 
    1, 1, '["First Law: Conservation of internal energy and work.", "Carnot engine gives upper efficiency limit.", "Entropy never decreases in natural processes."]'::jsonb, '["\\Delta U = Q - W", "\\eta = 1 - \\frac{Q_C}{Q_H}", "\\eta_{Carnot} = 1 - \\frac{T_C}{T_H}", "W = P\\Delta V"]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 14. SEED DATA - WORKSHEETS & STEP-BY-STEP SOLUTIONS
-- ---------------------------------------------------------------------
INSERT INTO public.worksheets (id, grade, subject, unit_number, title, questions_html, solutions_html, package_id)
VALUES
    ('ws_g12_math_u1', 12, 'Mathematics', 1, 'Unit 1: Sequences and Series Practice Problems',
    '<div class="worksheet-question"><h4>Question 1</h4><p>Find the 15th term of the arithmetic sequence: 3, 7, 11, 15, ...</p></div><div class="worksheet-question"><h4>Question 2</h4><p>Find the sum of the infinite geometric series: $12 + 6 + 3 + 1.5 + ...$</p></div>',
    '<div class="worksheet-solution"><h4>Solution 1</h4><p>Given $a_1 = 3$, $d = 7 - 3 = 4$.</p><p>Formula: $a_{15} = a_1 + (15 - 1)d = 3 + 14(4) = 3 + 56 = 59$.</p></div><div class="worksheet-solution"><h4>Solution 2</h4><p>Given $a_1 = 12$, $r = 6 / 12 = 0.5$. Since $|r| < 1$, the sum is:</p><p>$S_\infty = \frac{a_1}{1 - r} = \frac{12}{1 - 0.5} = \frac{12}{0.5} = 24$.</p></div>',
    'pkg_g12_mathematics')
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    questions_html = EXCLUDED.questions_html,
    solutions_html = EXCLUDED.solutions_html;

-- ---------------------------------------------------------------------
-- 15. SEED DATA - CURRICULUM QUIZ SYSTEM (Subjects, Units, Questions)
-- ---------------------------------------------------------------------
INSERT INTO public.subjects (id, name, grade)
VALUES
    ('12_mathematics', 'Mathematics', 12),
    ('12_physics', 'Physics', 12),
    ('11_chemistry', 'Chemistry', 11),
    ('10_mathematics', 'Mathematics', 10),
    ('9_biology', 'Biology', 9)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.units (id, subject_id, unit_number, title, description)
VALUES
    ('12_mathematics_1', '12_mathematics', 1, 'Sequences and Series', 'Arithmetic and geometric progressions, limits of sequences, infinite series.'),
    ('12_physics_1', '12_physics', 1, 'Thermodynamics', 'Laws of thermodynamics, heat engines, entropy, and thermal expansion.')
ON CONFLICT (id) DO NOTHING;

-- Sample Question 1
DO $$
DECLARE
    q_id UUID;
BEGIN
    INSERT INTO public.questions (unit_id, question_text, question_number, order_index, explanation)
    VALUES ('12_mathematics_1', 'What is the sum of the first 20 terms of an arithmetic progression whose first term is 5 and common difference is 3?', 1, 1, 'Using the formula S_n = n/2 * [2a + (n-1)d] with n=20, a=5, d=3: S_20 = 10 * [10 + 19*3] = 10 * [10 + 57] = 670.')
    RETURNING id INTO q_id;

    INSERT INTO public.question_options (question_id, text, is_correct, explanation)
    VALUES
        (q_id, '670', true, 'Correct! S_20 = 10 * (10 + 57) = 670.'),
        (q_id, '640', false, 'Incorrect calculation of the last term.'),
        (q_id, '720', false, 'Check formula: did not divide n by 2.'),
        (q_id, '580', false, 'Incorrect common difference multiplication.');
EXCEPTION WHEN OTHERS THEN
    -- Ignore duplicate on re-run
END $$;

-- ---------------------------------------------------------------------
-- 16. SEED DATA - VIDEOS TABLE
-- ---------------------------------------------------------------------
INSERT INTO public.videos (grade, subject, unit_number, title, youtube_video_id, duration_text, order_index)
VALUES
    (12, 'Mathematics', 1, 'Sequences and Series - Matric Prep Special', 'dQw4w9WgXcQ', '45:00', 1),
    (12, 'Physics', 1, 'Thermodynamics & Heat Engines Explained', 'dQw4w9WgXcQ', '38:15', 1),
    (11, 'Chemistry', 1, 'Atomic Structure and Chemical Bonding', 'dQw4w9WgXcQ', '28:40', 1),
    (10, 'Mathematics', 1, 'Polynomial & Rational Functions Deep-Dive', 'dQw4w9WgXcQ', '32:10', 1),
    (9, 'Biology', 1, 'Cell Biology and Microscopic Structures', 'dQw4w9WgXcQ', '22:15', 1)
ON CONFLICT (id) DO NOTHING;
