-- =====================================================================
-- SMART X ETHIOPIAN LEARNING APP - SUPABASE DATABASE MIGRATION
-- Admin-Issued Student Credentials, In-App Payments & Single-Device Locking
-- =====================================================================

-- 1. PACKAGES TABLE (Flexible Package Tiers: Single Subject, Stream, All-Inclusive Matric)
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

-- 2. WORKSHEETS TABLE (Step-by-step solutions with Math formula support)
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

-- 3. ADMIN-ISSUED STUDENT CREDENTIALS TABLE (Single-Device Hardware Bound)
CREATE TABLE IF NOT EXISTS public.student_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    password TEXT NOT NULL,
    package_id TEXT NOT NULL DEFAULT 'pkg_grade_12', -- e.g. 'pkg_grade_12', 'g12_all', 'g12_math', 'pkg_all_inclusive_g12'
    device_id TEXT, -- Hardware Device ID (e.g. AND_9F82A31B...). NULL allows first login to lock.
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_phone_cred UNIQUE(phone_number)
);

-- 4. USER SUBSCRIPTIONS TABLE (Historical & Multi-Package Sync)
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

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worksheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Packages Policy
DROP POLICY IF EXISTS "Allow public read packages" ON public.packages;
CREATE POLICY "Allow public read packages" ON public.packages
    FOR SELECT USING (true);

-- Worksheets Policy
DROP POLICY IF EXISTS "Allow public read worksheets" ON public.worksheets;
CREATE POLICY "Allow public read worksheets" ON public.worksheets
    FOR SELECT USING (true);

-- Student Credentials Policies
DROP POLICY IF EXISTS "Allow student credentials select" ON public.student_credentials;
CREATE POLICY "Allow student credentials select" ON public.student_credentials
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow student credentials device bind update" ON public.student_credentials;
CREATE POLICY "Allow student credentials device bind update" ON public.student_credentials
    FOR UPDATE USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow student credentials insert" ON public.student_credentials;
CREATE POLICY "Allow student credentials insert" ON public.student_credentials
    FOR INSERT WITH CHECK (true);

-- Subscriptions Policy
DROP POLICY IF EXISTS "Allow subscriptions all" ON public.user_subscriptions;
CREATE POLICY "Allow subscriptions all" ON public.user_subscriptions
    FOR ALL USING (true);

-- 6. SEED DATA FOR PACKAGES
INSERT INTO public.packages (id, title, grade, price_etb, description, badge_text, tier, subject, features)
VALUES
    -- Single Subject Packs (150 ETB)
    ('pkg_g12_mathematics', 'Grade 12 Mathematics Only', 12, 150.00, 'Complete Units 1–10 access for Grade 12 Mathematics. Full chapter notes, formula sheets, and step-by-step worksheets.', 'FOCUSED', 'single_subject', 'Mathematics', '["Full Grade 12 Math Units (1–10)", "Calculus & Vector Formulas", "Practice Worksheets & Solutions", "Single-Phone Offline Download"]'::jsonb),
    ('pkg_g12_physics', 'Grade 12 Physics Only', 12, 150.00, 'Complete Units 1–8 access for Grade 12 Physics. Full mechanics, wave & optics notes and worksheets.', 'FOCUSED', 'single_subject', 'Physics', '["Full Grade 12 Physics Units", "Formulas & Derivations", "Practice Worksheets & Solutions", "Single-Phone Offline Download"]'::jsonb),
    
    -- Stream / Grade All-Subjects Packs (400 ETB)
    ('pkg_grade_9', 'Grade 9 Foundation All-Subjects Pack', 9, 400.00, 'Complete access to all Grade 9 curriculum subjects (Math, Physics, Chemistry, Biology, English).', 'MOST POPULAR', 'stream_or_grade', NULL, '["All Grade 9 Subjects & Units", "Curriculum Short Notes", "Chapter Quizzes & Worksheets", "100% Offline Single Device"]'::jsonb),
    ('pkg_grade_10', 'Grade 10 National Exam (EGSECE) Booster', 10, 400.00, 'Complete Grade 10 curriculum with EGSECE model tests, formula sheets, and full unit worksheets.', 'EXAM READY', 'stream_or_grade', NULL, '["All Grade 10 Subjects Unlocked", "Solved Model Exams", "EGSECE Question Bank", "100% Offline Single Device"]'::jsonb),
    ('pkg_grade_11', 'Grade 11 Natural & Social Sciences Mastery', 11, 400.00, 'Full Grade 11 preparatory package covering all subjects with advanced practice problem sets.', 'PREP PACK', 'stream_or_grade', NULL, '["All Grade 11 Subjects Unlocked", "Advanced Problem Worksheets", "Step-by-step Solutions", "100% Offline Single Device"]'::jsonb),
    ('pkg_grade_12', 'Grade 12 Natural & Social Sciences All-Pack', 12, 400.00, 'Full Grade 12 curriculum package covering all subjects, short notes, quizzes, and unit worksheets.', 'ALL SUBJECTS', 'stream_or_grade', NULL, '["All Grade 12 Subjects Unlocked", "Complete Curriculum Notes", "All Unit Worksheets", "100% Offline Single Device"]'::jsonb),

    -- All-Inclusive Matric Prep Kits (600 ETB)
    ('pkg_all_inclusive_g12', 'Grade 12 University Entrance (EUEE) Master Package', 12, 600.00, 'Ultimate preparation bundle: All Grade 12 subjects + 10 Years Past Matric Exams Solved + Formula Cheat Sheets + Priority Telegram Tutor Support.', 'BEST VALUE', 'all_inclusive', NULL, '["Everything in All-Subjects Pack", "10+ Years Past EUEE Questions Solved", "Formula Flashcards & Cheat Sheets", "VIP Admin & Telegram Support", "Single-Device Anti-Loss Sync"]'::jsonb)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    price_etb = EXCLUDED.price_etb,
    description = EXCLUDED.description,
    badge_text = EXCLUDED.badge_text,
    tier = EXCLUDED.tier,
    subject = EXCLUDED.subject,
    features = EXCLUDED.features;

-- 7. SEED SAMPLE STUDENT CREDENTIALS FOR TESTING
INSERT INTO public.student_credentials (full_name, phone_number, password, package_id, device_id, is_active)
VALUES
    ('Abebe Kebede', '0911001122', 'smartx123', 'pkg_grade_12', NULL, true),
    ('Selamawit Tadesse', '0922334455', 'matric2026', 'pkg_all_inclusive_g12', NULL, true),
    ('Yohannes Hailu', '0933445566', 'mathpass12', 'pkg_g12_mathematics', NULL, true)
ON CONFLICT (phone_number) DO UPDATE SET
    password = EXCLUDED.password,
    package_id = EXCLUDED.package_id,
    is_active = EXCLUDED.is_active;
