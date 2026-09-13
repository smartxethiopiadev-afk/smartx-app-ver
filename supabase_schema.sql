-- =====================================================================
-- SMART X ETHIOPIAN LEARNING APP - SUPABASE DATABASE MIGRATION
-- Anti-Piracy, Dynamic Packages, Worksheets, Videos & Activation Codes
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

-- 3. USER SUBSCRIPTIONS & STRICT SINGLE-DEVICE BINDING TABLE
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    package_id TEXT NOT NULL,
    device_id TEXT, -- Hardware Device ID (e.g. AND_9F82A31B...). NULL allows next login to bind.
    is_active BOOLEAN DEFAULT true NOT NULL,
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_phone_package UNIQUE(phone_number, package_id)
);

-- 4. ACTIVATION CODES TABLE (Package-Specific Single-Device Bound Codes)
CREATE TABLE IF NOT EXISTS public.activation_codes (
    code TEXT PRIMARY KEY,
    package_id TEXT NOT NULL, -- e.g., 'pkg_g12_mathematics', 'pkg_g12_physics', 'pkg_grade_12', 'pkg_all_inclusive_g12'
    grade INT NOT NULL,
    subject TEXT, -- NULL if full grade package
    is_used BOOLEAN DEFAULT false,
    used_by_phone TEXT,
    used_by_device TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. VIDEOS TABLE (Unlisted YouTube Masterclasses & Curriculum Lessons)
CREATE TABLE IF NOT EXISTS public.videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INT NOT NULL,
    subject TEXT NOT NULL,
    unit_number INT NOT NULL,
    title TEXT NOT NULL,
    youtube_video_id TEXT NOT NULL,
    duration_text TEXT,
    order_index INT DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worksheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

-- Allow public read of packages
DROP POLICY IF EXISTS "Allow public read packages" ON public.packages;
CREATE POLICY "Allow public read packages" ON public.packages
    FOR SELECT USING (true);

-- Allow public read of worksheets
DROP POLICY IF EXISTS "Allow public read worksheets" ON public.worksheets;
CREATE POLICY "Allow public read worksheets" ON public.worksheets
    FOR SELECT USING (true);

-- Allow subscribers to read and verify their single-device binding
DROP POLICY IF EXISTS "Allow subscribers read subscriptions" ON public.user_subscriptions;
CREATE POLICY "Allow subscribers read subscriptions" ON public.user_subscriptions
    FOR SELECT USING (true);

-- Allow initial binding and updates
DROP POLICY IF EXISTS "Allow update subscription device binding" ON public.user_subscriptions;
CREATE POLICY "Allow update subscription device binding" ON public.user_subscriptions
    FOR ALL USING (true);

-- Allow code verification and single-device activation
DROP POLICY IF EXISTS "Allow code verification" ON public.activation_codes;
CREATE POLICY "Allow code verification" ON public.activation_codes
    FOR ALL USING (true);

-- Allow public read of videos
DROP POLICY IF EXISTS "Allow public read access to videos" ON public.videos;
CREATE POLICY "Allow public read access to videos" ON public.videos
    FOR SELECT USING (true);

-- 7. SEED DATA FOR PACKAGES (Single Subject, Grade All-In, Matric Prep)
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

-- 8. SAMPLE ACTIVATION CODES FOR TESTING
INSERT INTO public.activation_codes (code, package_id, grade, subject, is_used)
VALUES
    ('SMARTX-G12-MATH-2026', 'pkg_g12_mathematics', 12, 'Mathematics', false),
    ('SMARTX-G12-PHYS-2026', 'pkg_g12_physics', 12, 'Physics', false),
    ('SMARTX-G12-ALL-2026', 'pkg_grade_12', 12, NULL, false),
    ('SMARTX-G11-ALL-2026', 'pkg_grade_11', 11, NULL, false),
    ('SMARTX-G10-ALL-2026', 'pkg_grade_10', 10, NULL, false),
    ('SMARTX-G9-ALL-2026', 'pkg_grade_9', 9, NULL, false),
    ('SMARTX-MATRIC-PREP-2026', 'pkg_all_inclusive_g12', 12, NULL, false)
ON CONFLICT (code) DO NOTHING;

-- 9. SEED VIDEOS FOR UNLISTED YOUTUBE MASTERCLASSES
INSERT INTO public.videos (grade, subject, unit_number, title, youtube_video_id, duration_text, order_index)
VALUES
    (9, 'Mathematics', 1, 'Number Systems & Rational Operations', 'dQw4w9WgXcQ', '24:15', 1),
    (9, 'Physics', 1, 'Physics and Human Society Overview', 'dQw4w9WgXcQ', '18:30', 2),
    (10, 'Mathematics', 1, 'Polynomial & Rational Functions Deep-Dive', 'dQw4w9WgXcQ', '32:10', 1),
    (11, 'Chemistry', 1, 'Atomic Structure and Chemical Bonding', 'dQw4w9WgXcQ', '28:40', 1),
    (12, 'Mathematics', 1, 'Sequences and Series - Matric Prep Special', 'dQw4w9WgXcQ', '45:00', 1)
ON CONFLICT (id) DO NOTHING;
