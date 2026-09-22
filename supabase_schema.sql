-- =====================================================================
-- SMART LEARN ETHIOPIAN - PRODUCTION SUPABASE POSTGRESQL SCHEMA
-- =====================================================================
-- Architecture Highlights:
-- 1. Storage Buckets: 'videos' (Supabase Storage direct MP4/HLS streaming), 
--    'thumbnails', 'documents', 'avatars' with public RLS access.
-- 2. videos: Integrated with Supabase Storage URLs (video_url, storage_path, thumbnail_url).
-- 3. exam_questions: Dedicated Exam Mode table (MULTIPLE CHOICE ONLY) with timer & matric years.
-- 4. practice_questions: Dedicated Practice Mode table supporting 3 distinct question types:
--    - 'multiple_choice' (A, B, C, D choices)
--    - 'true_false' (True / False / እውነት / ሐሰት)
--    - 'blank_space' (Fill in the blank / ባዶ ቦታ ሙላ with synonyms, hints & validation)
-- 5. short_notes & worksheets: Comprehensive unit summaries, formulas & step-by-step solutions.
-- 6. students & student_credentials: Single-device hardware lock & subscription management.
-- 7. activation_codes: Concurrency-safe atomic activation codes with device binding.
-- 8. Row Level Security (RLS) & Performance Indexes.
-- =====================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- 1. SUPABASE STORAGE BUCKETS CONFIGURATION
-- =====================================================================
-- Create public storage buckets for videos, thumbnails, and curriculum documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('videos', 'videos', true, 524288000, ARRAY['video/mp4', 'video/webm', 'video/quicktime', 'application/x-mpegURL', 'video/MP2T']),
    ('thumbnails', 'thumbnails', true, 10485760, ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']),
    ('documents', 'documents', true, 52428800, ARRAY['application/pdf', 'application/json', 'text/plain']),
    ('avatars', 'avatars', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage Policies for Public Bucket Access
DROP POLICY IF EXISTS "Public Access to Videos Bucket" ON storage.objects;
CREATE POLICY "Public Access to Videos Bucket" ON storage.objects
    FOR SELECT USING (bucket_id = 'videos' OR bucket_id = 'thumbnails' OR bucket_id = 'documents' OR bucket_id = 'avatars');

DROP POLICY IF EXISTS "Service Role Upload to Storage" ON storage.objects;
CREATE POLICY "Service Role Upload to Storage" ON storage.objects
    FOR ALL USING (auth.role() = 'service_role' OR auth.role() = 'authenticated');

-- =====================================================================
-- 2. PACKAGES TABLE (Subscription Tiers & Subject Packs)
-- =====================================================================
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

-- =====================================================================
-- 3. STUDENTS TABLE (Primary Source of Truth for Accounts & Device Lock)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    grade INTEGER NOT NULL DEFAULT 9,
    stream TEXT DEFAULT 'Natural',
    device_id TEXT, -- Bound to first device hardware ID (anti-account sharing)
    unlocked_packages TEXT[] DEFAULT '{}', -- Array of package/subject IDs (e.g. 'pkg_g12_mathematics', 'pkg_grade_12')
    subscription_status TEXT DEFAULT 'free', -- 'free', 'active', 'expired'
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 4. STUDENT CREDENTIALS TABLE (Admin-Issued Login & Device Lock)
-- =====================================================================
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

-- =====================================================================
-- 5. USER SUBSCRIPTIONS & ACTIVATION CODES
-- =====================================================================
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

CREATE TABLE IF NOT EXISTS public.activation_codes (
    code TEXT PRIMARY KEY,
    package_id TEXT NOT NULL,
    grade INT NOT NULL,
    subject TEXT,
    duration_days INT DEFAULT 365,
    is_used BOOLEAN DEFAULT false,
    used_by_phone TEXT,
    used_by_device TEXT,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 6. VIDEOS TABLE (Now Powered by Supabase Storage Video Streaming)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INT NOT NULL,
    subject TEXT NOT NULL,
    unit_number INT NOT NULL,
    part_number INT DEFAULT 1, -- Part division (e.g. Part 1, Part 2, Part 3)
    title TEXT NOT NULL,
    description TEXT,
    -- Supabase Storage video streaming URL (or public CDN link)
    video_url TEXT,
    -- Supabase storage relative object path (e.g. 'grade12/math/unit1_part1.mp4')
    storage_path TEXT,
    -- Supabase Storage custom thumbnail URL
    thumbnail_url TEXT,
    -- Duration display (e.g. '24:15') and seconds
    duration_text TEXT DEFAULT '15 mins',
    duration_seconds INT,
    file_size_bytes BIGINT,
    order_index INT DEFAULT 1,
    is_free BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT true,
    -- Legacy/Fallback YouTube ID if needed
    youtube_video_id TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 6B. APP_TUTORIALS TABLE (Onboarding & How To Start Guide Videos via Supabase Storage)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.app_tutorials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT, -- Supabase storage public URL or direct MP4 link
    storage_path TEXT, -- e.g. 'tutorials/how_to_start_smart_learn.mp4'
    thumbnail_url TEXT, -- e.g. 'thumbnails/tutorial_banner.webp'
    duration_text TEXT DEFAULT '10 mins',
    order_index INT DEFAULT 1,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 7. EXAM_QUESTIONS TABLE (Exam Mode - MULTIPLE CHOICE ONLY)
-- Timed National Matric Exams, Unit Tests & Model Practice
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.exam_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INTEGER NOT NULL,
    subject TEXT NOT NULL,
    unit_number INTEGER DEFAULT 0, -- 0 for full-curriculum / national model exams, or 1-12 for unit exams
    year TEXT DEFAULT '2016 E.C.', -- e.g. '2016 E.C.', '2015 E.C.', '2024 Model'
    exam_category TEXT DEFAULT 'national_exam', -- 'national_exam', 'model_exam', 'unit_exam'
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    -- Option definitions
    option_a TEXT,
    option_b TEXT,
    option_c TEXT,
    option_d TEXT,
    -- Structured options JSONB: [{"key": "A", "text": "..."}, {"key": "B", "text": "..."}]
    options JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- The correct choice: 'A', 'B', 'C', or 'D'
    correct_option TEXT NOT NULL,
    correct_answer TEXT NOT NULL,
    explanation TEXT,
    time_limit_seconds INTEGER DEFAULT 90, -- Default 90 seconds per question in timed exam
    difficulty TEXT DEFAULT 'medium', -- 'easy', 'medium', 'hard'
    order_index INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 8. PRACTICE_QUESTIONS TABLE (Practice Mode - Multi-Format Learning)
-- Supports: 'multiple_choice', 'true_false', 'blank_space' (Fill in the blanks)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.practice_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INTEGER NOT NULL,
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    topic TEXT,
    -- Question Type: 'multiple_choice', 'true_false', 'blank_space', or 'matching'
    question_type TEXT NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'blank_space', 'matching')),
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    
    -- For 'multiple_choice':
    -- Format: [{"key": "A", "text": "...", "is_correct": true, "explanation": "..."}]
    options JSONB DEFAULT '[]'::jsonb,

    -- For 'true_false':
    -- correct_boolean: true (True/እውነት), false (False/ሐሰት)
    correct_boolean BOOLEAN,

    -- For 'blank_space' (Fill in the blank / ባዶ ቦታ ሙላ):
    -- Canonical correct word/phrase (e.g. 'Acceleration', '9.8', 'Kinetic Energy')
    blank_answer TEXT,
    -- Accepted variants/synonyms JSONB array (e.g. ["acceleration", "a", "rate of velocity change"])
    accepted_answers JSONB DEFAULT '[]'::jsonb,
    case_sensitive BOOLEAN DEFAULT false,

    -- For 'matching' (Matching / አዛምድ):
    -- Format: [{"left": "Term A", "right": "Definition A"}, {"left": "Term B", "right": "Definition B"}]
    matching_pairs JSONB DEFAULT '[]'::jsonb,

    -- General Correct Answer & Guidance
    correct_answer TEXT NOT NULL,
    hint TEXT, -- Hint that students can reveal during practice
    explanation TEXT, -- Detailed step-by-step explanation
    difficulty TEXT DEFAULT 'medium', -- 'easy', 'medium', 'hard'
    order_index INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 9. SHORT NOTES & WORKSHEETS TABLES
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.short_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INTEGER NOT NULL,
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    summary TEXT,
    pdf_url TEXT,
    file_size_mb NUMERIC(5, 2) DEFAULT 2.50,
    page_number INTEGER DEFAULT 1,
    order_index INTEGER DEFAULT 1,
    key_takeaways JSONB DEFAULT '[]'::jsonb,
    formulas JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

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

-- Legacy tables compatibility (subjects, units, questions)
CREATE TABLE IF NOT EXISTS public.subjects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    grade INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.units (
    id TEXT PRIMARY KEY,
    subject_id TEXT NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id TEXT,
    grade INTEGER DEFAULT 12,
    subject TEXT DEFAULT 'Mathematics',
    unit_number INTEGER DEFAULT 1,
    question_text TEXT NOT NULL,
    question_number INTEGER NOT NULL,
    order_index INTEGER DEFAULT 1,
    options JSONB DEFAULT '[]'::jsonb,
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

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT UNIQUE,
    full_name TEXT,
    grade INTEGER,
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 10. HIGH PERFORMANCE DATABASE INDEXES
-- =====================================================================
CREATE INDEX IF NOT EXISTS idx_videos_lookup ON public.videos (grade, subject, unit_number, order_index);
CREATE INDEX IF NOT EXISTS idx_exam_questions_lookup ON public.exam_questions (grade, subject, unit_number, order_index);
CREATE INDEX IF NOT EXISTS idx_exam_questions_year ON public.exam_questions (grade, subject, year);
CREATE INDEX IF NOT EXISTS idx_practice_questions_lookup ON public.practice_questions (grade, subject, unit_number, order_index);
CREATE INDEX IF NOT EXISTS idx_practice_questions_type ON public.practice_questions (grade, subject, unit_number, question_type);
CREATE INDEX IF NOT EXISTS idx_short_notes_lookup ON public.short_notes (grade, subject, unit_number, order_index);
CREATE INDEX IF NOT EXISTS idx_worksheets_lookup ON public.worksheets (grade, subject, unit_number);
CREATE INDEX IF NOT EXISTS idx_students_phone ON public.students (phone_number);
CREATE INDEX IF NOT EXISTS idx_activation_codes_code ON public.activation_codes (code);

-- =====================================================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.short_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worksheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop and Recreate Public Read Policies
DROP POLICY IF EXISTS "Public Read Packages" ON public.packages;
CREATE POLICY "Public Read Packages" ON public.packages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Videos" ON public.videos;
CREATE POLICY "Public Read Videos" ON public.videos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Exam Questions" ON public.exam_questions;
CREATE POLICY "Public Read Exam Questions" ON public.exam_questions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Read Practice Questions" ON public.practice_questions;
CREATE POLICY "Public Read Practice Questions" ON public.practice_questions FOR SELECT USING (true);

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

DROP POLICY IF EXISTS "Public Read Students" ON public.students;
CREATE POLICY "Public Read Students" ON public.students FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Insert Students" ON public.students;
CREATE POLICY "Public Insert Students" ON public.students FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public Update Students Device And Profile" ON public.students;
CREATE POLICY "Public Update Students Device And Profile" ON public.students FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Read Student Credentials" ON public.student_credentials;
CREATE POLICY "Public Read Student Credentials" ON public.student_credentials FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Update Student Credentials Device" ON public.student_credentials;
CREATE POLICY "Public Update Student Credentials Device" ON public.student_credentials FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Subscriptions Access" ON public.user_subscriptions;
CREATE POLICY "Public Subscriptions Access" ON public.user_subscriptions FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Read Activation Codes" ON public.activation_codes;
CREATE POLICY "Public Read Activation Codes" ON public.activation_codes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Update Activation Codes" ON public.activation_codes;
CREATE POLICY "Public Update Activation Codes" ON public.activation_codes FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public Profiles Access" ON public.profiles;
CREATE POLICY "Public Profiles Access" ON public.profiles FOR ALL USING (true);

-- =====================================================================
-- 12. RPC FUNCTIONS: ACTIVATION & TELEGRAM UPGRADE
-- =====================================================================
CREATE OR REPLACE FUNCTION public.redeem_activation_code(
    p_code TEXT,
    p_phone TEXT,
    p_name TEXT,
    p_device_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code_record RECORD;
    v_pkg_id TEXT;
    v_grade INT;
    v_subject TEXT;
    v_duration INT;
    v_expires_at TIMESTAMPTZ;
    v_clean_phone TEXT := regexp_replace(trim(p_phone), '\s+', '', 'g');
    v_clean_code TEXT := upper(regexp_replace(trim(p_code), '\s+', '', 'g'));
BEGIN
    SELECT * INTO v_code_record
    FROM public.activation_codes
    WHERE upper(code) = v_clean_code
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 'invalid_code',
            'message', 'የተሳሳተ የማግበሪያ ኮድ። እባክዎ በትክክል ያረጋግጡ። / Invalid activation code.'
        );
    END IF;

    v_pkg_id := v_code_record.package_id;
    v_grade := v_code_record.grade;
    v_subject := v_code_record.subject;
    v_duration := COALESCE(v_code_record.duration_days, 365);
    v_expires_at := now() + (v_duration || ' days')::interval;

    IF v_code_record.is_used THEN
        IF v_code_record.used_by_device = p_device_id OR v_code_record.used_by_phone = v_clean_phone THEN
            UPDATE public.students
            SET unlocked_packages = array_append(array_remove(unlocked_packages, v_pkg_id), v_pkg_id),
                subscription_status = 'active',
                device_id = COALESCE(device_id, p_device_id),
                updated_at = now()
            WHERE phone_number = v_clean_phone;

            RETURN jsonb_build_object(
                'success', true,
                'status', 'already_used_same_device',
                'package_id', v_pkg_id,
                'grade', v_grade,
                'subject', v_subject,
                'message', 'ይህ ኮድ ቀደም ሲል ለዚህ ስልክ የተከፈተ ነው። መዳረሻው ታድሷል!'
            );
        ELSE
            RETURN jsonb_build_object(
                'success', false,
                'status', 'device_mismatch',
                'message', 'ይህ የማግበሪያ ኮድ በሌላ ስልክ ላይ አገልግሎት ላይ ውሏል! የደህንነት ስርዓቱ አንድን ኮድ ለአንድ ስልክ ብቻ ይፈቅዳል።'
            );
        END IF;
    END IF;

    UPDATE public.activation_codes
    SET is_used = true,
        used_by_phone = v_clean_phone,
        used_by_device = p_device_id,
        used_at = now()
    WHERE upper(code) = v_clean_code;

    INSERT INTO public.students (
        phone_number, full_name, grade, device_id,
        unlocked_packages, subscription_status, subscription_expires_at, is_active, updated_at
    )
    VALUES (
        v_clean_phone, p_name, v_grade, p_device_id,
        ARRAY[v_pkg_id], 'active', v_expires_at, true, now()
    )
    ON CONFLICT (phone_number) DO UPDATE SET
        unlocked_packages = array_append(array_remove(public.students.unlocked_packages, v_pkg_id), v_pkg_id),
        subscription_status = 'active',
        subscription_expires_at = v_expires_at,
        device_id = COALESCE(public.students.device_id, p_device_id),
        updated_at = now();

    INSERT INTO public.user_subscriptions (phone_number, package_id, device_id, is_active, activated_at)
    VALUES (v_clean_phone, v_pkg_id, p_device_id, true, now())
    ON CONFLICT (phone_number, package_id) DO UPDATE SET
        is_active = true,
        device_id = p_device_id,
        activated_at = now();

    RETURN jsonb_build_object(
        'success', true,
        'status', 'success',
        'package_id', v_pkg_id,
        'grade', v_grade,
        'subject', v_subject,
        'expires_at', v_expires_at,
        'message', 'እንኳን ደስ አለዎት! ይዘቱ በተሳካ ሁኔታ ተከፍቷል!'
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_and_upgrade_student(
    p_phone TEXT,
    p_name TEXT,
    p_device_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_clean_phone TEXT;
    v_student RECORD;
    v_bound_device TEXT;
    v_unlocked_pkgs JSONB;
BEGIN
    v_clean_phone := REGEXP_REPLACE(p_phone, '[^0-9+]', '', 'g');
    IF v_clean_phone LIKE '+251%' THEN
        v_clean_phone := '0' || SUBSTRING(v_clean_phone FROM 5);
    ELSIF v_clean_phone LIKE '251%' THEN
        v_clean_phone := '0' || SUBSTRING(v_clean_phone FROM 4);
    END IF;

    SELECT * INTO v_student
    FROM public.students
    WHERE phone_number = v_clean_phone;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 'not_found',
            'message', 'በዚህ ስልክ ቁጥር የተመዘገበ ተማሪ አልተገኘም። እባክዎ በቴሌግራም (@smart_x_help) ክፍያ ፈጽመው ደረሰኝ ይላኩ።'
        );
    END IF;

    IF v_student.is_active = false THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 'account_disabled',
            'message', 'ይህ መለያ በአስተዳዳሪው ታግዷል። እባክዎ ድጋፍ ያነጋግሩ (@smart_x_help)።'
        );
    END IF;

    IF v_student.subscription_expires_at IS NOT NULL AND v_student.subscription_expires_at < NOW() THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 'expired',
            'message', 'የደንበኝነት ምዝገባዎ ጊዜ አልቋል። እባክዎ በቴሌግራም ያድሱ (@smart_x_help)።'
        );
    END IF;

    v_bound_device := TRIM(COALESCE(v_student.device_id, ''));
    IF v_bound_device <> '' AND v_bound_device <> p_device_id THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 'device_mismatch',
            'message', 'ይህ ስልክ ቁጥር ቀደም ሲል በሌላ ሞባይል ስልክ ላይ ተመዝግቧል! የደህንነት ስርዓቱ አንድን አካውንት ለአንድ ስልክ ብቻ ይፈቅዳል (Single-Device Protection)።'
        );
    END IF;

    IF v_bound_device = '' THEN
        UPDATE public.students
        SET device_id = p_device_id,
            full_name = TRIM(p_name),
            updated_at = NOW()
        WHERE phone_number = v_clean_phone;
    ELSE
        UPDATE public.students
        SET full_name = TRIM(p_name),
            updated_at = NOW()
        WHERE phone_number = v_clean_phone;
    END IF;

    v_unlocked_pkgs := COALESCE(to_jsonb(v_student.unlocked_packages), '[]'::jsonb);

    IF jsonb_array_length(v_unlocked_pkgs) = 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 'no_packages',
            'message', 'ስልክ ቁጥርዎ ተገኝቷል፤ ነገር ግን እስካሁን የተፈቀደ ንቁ የትምህርት ፓኬጅ የለም። ክፍያ ፈጽመው ከሆነ እባክዎ ደረሰኝዎን በቴሌግራም (@smart_x_help) ለአድሚኑ ይላኩ።'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'status', 'upgraded',
        'message', 'እንኳን ደስ አለዎት! የትምህርት ፈቃድዎ በዚህ ስልክ ላይ በተሳካ ሁኔታ ተረጋግጦ ተከፍቷል!',
        'student_name', TRIM(p_name),
        'phone_number', v_clean_phone,
        'grade', COALESCE(v_student.grade, 12),
        'unlocked_packages', v_unlocked_pkgs
    );
END;
$$;

-- =====================================================================
-- 13. SEED DATA - PACKAGES
-- =====================================================================
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

-- =====================================================================
-- 14. SEED DATA - SUPABASE STORAGE VIDEOS
-- =====================================================================
INSERT INTO public.videos (
    grade, subject, unit_number, part_number, title, description,
    video_url, storage_path, thumbnail_url, duration_text, duration_seconds, order_index, is_free, is_published
)
VALUES
    (12, 'Mathematics', 1, 1, 'Sequences and Series: Arithmetic Progressions Deep Dive', 'Introduction to sequences, general terms of AP, and series summation formulas.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 'videos/grade12/math/unit1_part1.mp4', 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600&q=80', '28:14', 1694, 1, true, true),
    (12, 'Mathematics', 1, 2, 'Geometric Sequences & Infinite Series Convergence', 'Mastering geometric ratios, infinite geometric series sums, and convergence limits.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 'videos/grade12/math/unit1_part2.mp4', 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=600&q=80', '34:20', 2060, 2, false, true),
    (12, 'Physics', 1, 1, 'Thermodynamics: The First Law & Work Done in Gas Expansion', 'Conservation of thermal energy, isobaric/isochoric/isothermal processes walkthrough.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 'videos/grade12/physics/unit1_part1.mp4', 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600&q=80', '31:45', 1905, true, true),
    (12, 'Physics', 1, 2, 'Heat Engines, Carnot Cycle and Entropy Derivations', 'Second law of thermodynamics, Carnot engine maximum efficiency formulas and solved matric questions.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', 'videos/grade12/physics/unit1_part2.mp4', 'https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=600&q=80', '26:50', 1610, false, true),
    (11, 'Chemistry', 1, 1, 'Atomic Structure and Modern Quantum Theory', 'Bohr model limitations, quantum numbers (n, l, m, s), and electron configurations.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4', 'videos/grade11/chemistry/unit1_part1.mp4', 'https://images.unsplash.com/photo-1603126857599-f6e157fa2fe6?w=600&q=80', '24:10', 1450, true, true),
    (10, 'Mathematics', 1, 1, 'Polynomial & Rational Functions Comprehensive Guide', 'Degree of polynomials, synthetic division, and graph asymptotes.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4', 'videos/grade10/math/unit1_part1.mp4', 'https://images.unsplash.com/photo-1596495578065-6e0763fa1178?w=600&q=80', '29:30', 1770, true, true),
    (9, 'Biology', 1, 1, 'Cell Structure, Organelles and Microscope Techniques', 'Prokaryotic vs Eukaryotic cells, plant vs animal organelle functions.', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4', 'videos/grade9/biology/unit1_part1.mp4', 'https://images.unsplash.com/photo-1530210124550-912dc1381cb8?w=600&q=80', '21:05', 1265, true, true)
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- 15. SEED DATA - EXAM_QUESTIONS (EXAM MODE - MULTIPLE CHOICE ONLY)
-- =====================================================================
INSERT INTO public.exam_questions (
    grade, subject, unit_number, year, exam_category, question_number,
    question_text, option_a, option_b, option_c, option_d, options,
    correct_option, correct_answer, explanation, time_limit_seconds, difficulty, order_index
)
VALUES
    -- Grade 12 Math Exam Q1
    (12, 'Mathematics', 1, '2016 E.C.', 'national_exam', 1,
    'What is the sum of the first 20 terms of an arithmetic progression whose first term is 5 and common difference is 3?',
    '640', '670', '720', '580',
    '[{"key": "A", "text": "640"}, {"key": "B", "text": "670"}, {"key": "C", "text": "720"}, {"key": "D", "text": "580"}]'::jsonb,
    'B', '670',
    'Formula: $S_n = \frac{n}{2}[2a_1 + (n-1)d]$. For $n=20, a_1=5, d=3$: $S_{20} = \frac{20}{2}[2(5) + 19(3)] = 10[10 + 57] = 10(67) = 670$.',
    90, 'medium', 1),

    -- Grade 12 Math Exam Q2
    (12, 'Mathematics', 1, '2016 E.C.', 'national_exam', 2,
    'For what value of $r$ does the infinite geometric series $18 + 18r + 18r^2 + ...$ converge to 27?',
    '1/3', '2/3', '-1/3', '1/2',
    '[{"key": "A", "text": "1/3"}, {"key": "B", "text": "2/3"}, {"key": "C", "text": "-1/3"}, {"key": "D", "text": "1/2"}]'::jsonb,
    'A', '1/3',
    'The sum of an infinite geometric series is $S_\infty = \frac{a_1}{1 - r}$. Setting $27 = \frac{18}{1 - r} \implies 1 - r = \frac{18}{27} = \frac{2}{3} \implies r = 1 - \frac{2}{3} = \frac{1}{3}$.',
    90, 'medium', 2),

    -- Grade 12 Physics Exam Q1
    (12, 'Physics', 1, '2016 E.C.', 'national_exam', 1,
    'A heat engine absorbs 1200 J of heat from a hot reservoir at 600 K and exhausts 400 J to a cold reservoir. What is the actual thermal efficiency of the engine?',
    '33.3%', '50.0%', '66.7%', '75.0%',
    '[{"key": "A", "text": "33.3%"}, {"key": "B", "text": "50.0%"}, {"key": "C", "text": "66.7%"}, {"key": "D", "text": "75.0%"}]'::jsonb,
    'C', '66.7%',
    'Efficiency $\eta = 1 - \frac{Q_C}{Q_H} = 1 - \frac{400}{1200} = 1 - \frac{1}{3} = \frac{2}{3} \approx 66.7\%$.',
    90, 'medium', 1),

    -- Grade 12 Physics Exam Q2
    (12, 'Physics', 1, '2015 E.C.', 'national_exam', 2,
    'During an adiabatic expansion of an ideal gas, which of the following statements is strictly TRUE?',
    'Heat added to the system $Q > 0$', 'No heat enters or leaves the system ($Q = 0$)', 'The internal energy remains constant ($\Delta U = 0$)', 'The temperature of the gas always increases',
    '[{"key": "A", "text": "Heat added to the system Q > 0"}, {"key": "B", "text": "No heat enters or leaves the system (Q = 0)"}, {"key": "C", "text": "The internal energy remains constant (ΔU = 0)"}, {"key": "D", "text": "The temperature of the gas always increases"}]'::jsonb,
    'B', 'No heat enters or leaves the system (Q = 0)',
    'By definition, an adiabatic process is a thermodynamic process in which no heat is transferred into or out of the system ($Q = 0$). Thus $\Delta U = -W$.',
    90, 'easy', 2),

    -- Grade 11 Chemistry Exam Q1
    (11, 'Chemistry', 1, '2016 E.C.', 'national_exam', 1,
    'Which set of quantum numbers ($n, l, m_l, m_s$) is NOT allowed for an electron in an atom?',
    '(3, 2, -2, +1/2)', '(2, 1, 0, -1/2)', '(3, 3, 0, +1/2)', '(4, 0, 0, +1/2)',
    '[{"key": "A", "text": "(3, 2, -2, +1/2)"}, {"key": "B", "text": "(2, 1, 0, -1/2)"}, {"key": "C", "text": "(3, 3, 0, +1/2)"}, {"key": "D", "text": "(4, 0, 0, +1/2)"}]'::jsonb,
    'C', '(3, 3, 0, +1/2)',
    'The angular momentum quantum number $l$ can only take integer values from $0$ up to $n-1$. When $n=3$, $l$ can only be $0, 1,$ or $2$. Therefore, $l=3$ is invalid.',
    90, 'medium', 1)
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- 16. SEED DATA - PRACTICE_QUESTIONS (PRACTICE MODE - 4 QUESTION FORMATS)
-- Types: 'multiple_choice', 'true_false', 'blank_space' (Fill in the blank), 'matching' (አዛምድ)
-- =====================================================================
INSERT INTO public.practice_questions (
    grade, subject, unit_number, topic, question_type, question_number,
    question_text, options, correct_boolean, blank_answer, accepted_answers, matching_pairs,
    correct_answer, hint, explanation, difficulty, order_index
)
VALUES
    -- Type 1: Multiple Choice (Math G12 Unit 1)
    (12, 'Mathematics', 1, 'Arithmetic Sequences', 'multiple_choice', 1,
    'What is the 10th term of the arithmetic progression with first term $a_1 = 4$ and common difference $d = 5$?',
    '[{"key": "A", "text": "45", "is_correct": false}, {"key": "B", "text": "49", "is_correct": true, "explanation": "a_10 = 4 + 9(5) = 49"}, {"key": "C", "text": "54", "is_correct": false}, {"key": "D", "text": "50", "is_correct": false}]'::jsonb,
    NULL, NULL, '[]'::jsonb, '[]'::jsonb,
    '49',
    'Use the general AP term formula: $a_n = a_1 + (n - 1)d$.',
    'Using $a_n = a_1 + (n-1)d$: $a_{10} = 4 + (10 - 1)(5) = 4 + 45 = 49$.',
    'easy', 1),

    -- Type 2: True / False (Math G12 Unit 1)
    (12, 'Mathematics', 1, 'Infinite Geometric Series', 'true_false', 2,
    'True or False: An infinite geometric series converges if and only if the absolute value of the common ratio is strictly less than 1 ($|r| < 1$).',
    '[]'::jsonb,
    true, NULL, '[]'::jsonb, '[]'::jsonb,
    'True',
    'Recall the condition for the limit of $r^n$ as $n \to \infty$.',
    'True. When $|r| < 1$, the terms approach zero and the infinite sum converges to $S_\infty = \frac{a_1}{1 - r}$. If $|r| \ge 1$, the series diverges.',
    'easy', 2),

    -- Type 3: Blank Space / Fill-in-the-blank (Math G12 Unit 1)
    (12, 'Mathematics', 1, 'Harmonic Progression', 'blank_space', 3,
    'A sequence is called a Harmonic Progression (HP) if the reciprocals of its terms form an _______ progression.',
    '[]'::jsonb,
    NULL, 'Arithmetic', '["arithmetic", "arithmetic progression", "AP", "ap"]'::jsonb, '[]'::jsonb,
    'Arithmetic',
    'Think of the fundamental sequence type whose reciprocal generates harmonic numbers.',
    'By definition, a sequence $h_1, h_2, h_3, ...$ is a Harmonic Progression if $\frac{1}{h_1}, \frac{1}{h_2}, \frac{1}{h_3}, ...$ forms an Arithmetic Progression (AP).',
    'medium', 3),

    -- Type 4: Matching / አዛምድ (Math G12 Unit 1)
    (12, 'Mathematics', 1, 'Sequences Classifications', 'matching', 4,
    'Match each sequence type in Column A with its defining property in Column B (በአምድ "ሀ" ስር ያሉትን ከአምድ "ለ" ጋር አዛምዱ):',
    '[]'::jsonb,
    NULL, NULL, '[]'::jsonb,
    '[{"left": "Arithmetic Progression (AP)", "right": "Constant difference between consecutive terms (d)"}, {"left": "Geometric Progression (GP)", "right": "Constant ratio between consecutive terms (r)"}, {"left": "Harmonic Progression (HP)", "right": "Reciprocals form an arithmetic sequence"}, {"left": "Fibonacci Sequence", "right": "Each term is the sum of the two preceding ones"}]'::jsonb,
    'Matching completed',
    'Consider how consecutive terms are generated in each standard mathematical sequence.',
    'AP adds a constant difference d; GP multiplies by a constant ratio r; HP consists of reciprocals of an AP; Fibonacci adds the prior two terms.',
    'medium', 4),

    -- Type 1: Multiple Choice (Physics G12 Unit 1)
    (12, 'Physics', 1, 'First Law of Thermodynamics', 'multiple_choice', 1,
    'According to the First Law of Thermodynamics, if 500 J of heat is added to a system and the system performs 200 J of work on its surroundings, what is the change in internal energy ($\Delta U$)?',
    '[{"key": "A", "text": "700 J", "is_correct": false}, {"key": "B", "text": "300 J", "is_correct": true, "explanation": "ΔU = Q - W = 500 - 200 = 300 J"}, {"key": "C", "text": "-300 J", "is_correct": false}, {"key": "D", "text": "2.5 J", "is_correct": false}]'::jsonb,
    NULL, NULL, '[]'::jsonb, '[]'::jsonb,
    '300 J',
    'Apply $\Delta U = Q - W$, noting that work done by the system is positive.',
    'First Law: $\Delta U = Q - W = 500\text{ J} - 200\text{ J} = 300\text{ J}$.',
    'easy', 1),

    -- Type 2: True / False (Physics G12 Unit 1)
    (12, 'Physics', 1, 'Second Law of Thermodynamics', 'true_false', 2,
    'True or False: According to the Second Law of Thermodynamics, heat can spontaneously flow from a colder body to a hotter body without external work.',
    '[]'::jsonb,
    false, NULL, '[]'::jsonb, '[]'::jsonb,
    'False',
    'Consider Clausius statement of the Second Law of Thermodynamics.',
    'False. Clausius Statement: It is impossible to construct a device that operates in a cycle and produces no effect other than the transfer of heat from a cooler body to a hotter body.',
    'easy', 2),

    -- Type 3: Blank Space / Fill-in-the-blank (Physics G12 Unit 1)
    (12, 'Physics', 1, 'Carnot Heat Engines', 'blank_space', 3,
    'The maximum theoretical efficiency of any heat engine operating between two thermal reservoirs is called the _______ efficiency.',
    '[]'::jsonb,
    NULL, 'Carnot', '["carnot", "Carnot efficiency", "carnot efficiency", "Carnot cycle"]'::jsonb, '[]'::jsonb,
    'Carnot',
    'Named after the French physicist Nicolas Léonard Sadi _______',
    'The Carnot efficiency $\eta_{Carnot} = 1 - \frac{T_C}{T_H}$ establishes the upper thermodynamic limit on efficiency for any heat engine operating between temperatures $T_H$ and $T_C$.',
    'medium', 3),

    -- Type 4: Matching / አዛምድ (Physics G12 Unit 1)
    (12, 'Physics', 1, 'Thermodynamic Processes', 'matching', 4,
    'Match each thermodynamic process with its key characteristic (የሙቀት ሂደቶችን ከባህሪያቸው ጋር አዛምዱ):',
    '[]'::jsonb,
    NULL, NULL, '[]'::jsonb,
    '[{"left": "Isobaric Process", "right": "Constant Pressure (ΔP = 0)"}, {"left": "Isochoric (Isovolumetric)", "right": "Constant Volume (W = 0, ΔV = 0)"}, {"left": "Isothermal Process", "right": "Constant Temperature (ΔU = 0 for ideal gas)"}, {"left": "Adiabatic Process", "right": "No heat exchange with surroundings (Q = 0)"}]'::jsonb,
    'Matching completed',
    'Look at the Greek roots: baros (pressure), chora (space/volume), therme (heat/temperature), adiabatos (impassable/no heat).',
    'Isobaric: constant pressure; Isochoric: constant volume; Isothermal: constant temperature; Adiabatic: zero heat transfer.',
    'medium', 4),

    -- Type 4: Matching / አዛምድ (Biology G9 Unit 1)
    (9, 'Biology', 1, 'Cell Organelles and Functions', 'matching', 1,
    'Match each cell organelle with its primary biological function (የሴል ክፍሎችን ከስራቸው ጋር አዛምዱ):',
    '[]'::jsonb,
    NULL, NULL, '[]'::jsonb,
    '[{"left": "Mitochondria", "right": "Powerhouse of cell; generates ATP via cellular respiration"}, {"left": "Ribosome", "right": "Site of protein synthesis"}, {"left": "Chloroplast", "right": "Site of photosynthesis in plant cells"}, {"left": "Nucleus", "right": "Stores genetic material (DNA) and directs cell activities"}]'::jsonb,
    'Matching completed',
    'Recall which organelle is responsible for cellular energy versus protein manufacturing.',
    'Mitochondria produces ATP; ribosomes assemble polypeptides; chloroplasts conduct photosynthesis; nucleus contains chromosomes.',
    'easy', 1),

    -- Type 3: Blank Space (Chemistry G11 Unit 1)
    (11, 'Chemistry', 1, 'Atomic Orbitals', 'blank_space', 1,
    'The quantum number that determines the spatial orientation of an atomic orbital is the _______ quantum number.',
    '[]'::jsonb,
    NULL, 'Magnetic', '["magnetic", "magnetic quantum number", "m_l", "ml"]'::jsonb, '[]'::jsonb,
    'Magnetic',
    'Denoted as $m_l$ or $m$.',
    'The magnetic quantum number ($m_l$) specifies the orientation in space of an orbital of a given energy ($n$) and shape ($l$).',
    'medium', 1)
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- 17. SEED DATA - SAMPLE STUDENTS & ACTIVATION CODES
-- =====================================================================
INSERT INTO public.students (full_name, phone_number, grade, stream, unlocked_packages, subscription_status, is_active)
VALUES
    ('Habtamu Yifiru', '0978254242', 12, 'Natural', ARRAY['pkg_all_inclusive_g12', 'all_grades'], 'active', true),
    ('Abebe Bikila', '0911223344', 12, 'Natural', ARRAY['pkg_grade_12'], 'active', true),
    ('Tirunesh Dibaba', '0922334455', 11, 'Natural', ARRAY['pkg_g11_mathematics'], 'active', true),
    ('Free Demo Student', '0900000000', 12, 'Natural', ARRAY[]::text[], 'free', true)
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO public.student_credentials (full_name, phone_number, password, package_id, is_active)
VALUES
    ('Habtamu Yifiru', '0978254242', 'smartx2026', 'pkg_all_inclusive_g12', true),
    ('Abebe Bikila', '0911223344', 'abebe123', 'pkg_grade_12', true),
    ('Tirunesh Dibaba', '0922334455', 'tiru2026', 'pkg_grade_11', true),
    ('Kenenisa Bekele', '0933445566', 'ken2026', 'pkg_grade_10', true),
    ('Derartu Tulu', '0944556677', 'derartu99', 'pkg_grade_9', true)
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO public.activation_codes (code, package_id, grade, subject, duration_days, is_used)
VALUES
    ('SMARTX-G12-MATH', 'pkg_g12_mathematics', 12, 'Mathematics', 365, false),
    ('SMARTX-G12-PHYS', 'pkg_g12_physics', 12, 'Physics', 365, false),
    ('SMARTX-G12-FULL', 'pkg_grade_12', 12, NULL, 365, false),
    ('SMARTX-G11-FULL', 'pkg_grade_11', 11, NULL, 365, false),
    ('SMARTX-G10-FULL', 'pkg_grade_10', 10, NULL, 365, false),
    ('SMARTX-G9-FULL', 'pkg_grade_9', 9, NULL, 365, false),
    ('SMARTX-MATRIC-VIP', 'pkg_all_inclusive_g12', 12, NULL, 365, false)
ON CONFLICT (code) DO NOTHING;

-- =====================================================================
-- 18. SEED DATA - CURRICULUM SHORT NOTES & WORKSHEET MATERIALS
-- =====================================================================
INSERT INTO public.short_notes (
    grade, subject, unit_number, title, content, summary, pdf_url, file_size_mb, page_number, order_index, key_takeaways, formulas
)
VALUES
    -- Grade 12 Mathematics Unit 1
    (12, 'Mathematics', 1, 'Sequences and Series (አከታተልና ተከታታይ)', 
    'A sequence is a function whose domain is the set of positive integers. Unit 1 covers Arithmetic & Geometric Sequences and Series, convergence/divergence rules, and infinite geometric sums.',
    'ይህ ምዕራፍ ስለ አከታተል (Sequences) እና ተከታታይ (Series) ጽንሰ-ሀሳቦችን ያብራራል። የአርቲሜቲክ (Arithmetic) እና ጂኦሜትሪክ (Geometric) ቀመሮችን፣ የአጠቃላይ ተርም (n-th term) አወጣጥን፣ እንዲሁም ተከታታዮች መቼ ኮንቨርጅ (converge) ወይም ዳይቨርጅ (diverge) እንደሚያደርጉ በዝርዝር ያስተምራል።',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 1.85, 1, 1,
    '["A sequence is a ordered list of numbers with a defined term pattern.", "An Arithmetic Progression increases by a constant common difference (d).", "A Geometric Progression multiplies by a constant common ratio (r).", "An infinite geometric series converges if and only if |r| < 1."]'::jsonb,
    '["Arithmetic general term: a_n = a_1 + (n-1)d", "Arithmetic series sum: S_n = (n/2)(2a_1 + (n-1)d)", "Geometric general term: a_n = a_1 * r^(n-1)", "Infinite geometric sum: S_inf = a_1 / (1 - r) for |r| < 1"]'::jsonb),

    -- Grade 12 Physics Unit 1
    (12, 'Physics', 1, 'Thermodynamics (ቴርሞዳይናሚክስ - የሙቀት ህጎች)',
    'Thermodynamics is the study of heat, work, and the associated conversion of energy. Unit 1 details the First and Second Laws of Thermodynamics, thermodynamic processes (isobaric, isothermal, isochoric, adiabatic), and Carnot Heat Engine efficiency.',
    'ቴርሞዳይናሚክስ ስለ ሙቀት፣ ስራ እና የሃይል ልውውጦች የሚያጠና የፊዚክስ ክፍል ነው። ይህ ምዕራፍ አንደኛውንና ሁለተኛውን የቴርሞዳይናሚክስ ህጎች፣ አራቱን ዋና ዋና የሙቀት ሂደቶች (ኢሶባሪክ፣ ኢሶተርማል፣ ኢሶኮሪክ፣ አዲያባቲክ)፣ እና የካርኖት ሂት ኢንጂን (Carnot Heat Engine) ቅልጥፍናን ያብራራል።',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 2.10, 1, 1,
    '["The First Law states energy cannot be created or destroyed: dU = Q - W.", "Isobaric process occurs at constant pressure.", "Isothermal process occurs at constant temperature (dU = 0).", "Adiabatic process has no heat exchange with surroundings (Q = 0).", "Entropy of any closed system always increases over time."]'::jsonb,
    '["First Law of Thermodynamics: dU = Q - W", "Work done in Gas Expansion: W = P * dV", "Carnot Engine Ideal Efficiency: n_Carnot = 1 - (T_C / T_H)", "Entropy change: dS = dQ / T"]'::jsonb),

    -- Grade 11 Chemistry Unit 1
    (11, 'Chemistry', 1, 'Atomic Structure and Periodicity (አቶሚክ መዋቅርና ወቅታዊነት)',
    'Unit 1 covers quantum numbers, electron configurations, rules of Aufbau, Hund, and Pauli exclusion principle, and chemical periodicity trends across the periodic table.',
    'ይህ ምዕራፍ ስለ አቶም መዋቅር፣ የኳንተም ቁጥሮች (Quantum Numbers)፣ የኤሌክትሮን ውቅር አጻጻፍ ደንቦች (Aufbau Principle, Hund''s Rule, Pauli Exclusion) እና የፔሬዲክ ቴብል ኬሚካዊ ባህሪያት ለውጥን (Periodicity) ይተነትናል።',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 3.20, 1, 1,
    '["Principal quantum number (n) specifies orbital energy level.", "Angular momentum (l) determines the shape of the orbital.", "Magnetic quantum number (m) determines spatial orientation.", "Aufbau Principle states electrons fill lower energy levels first."]'::jsonb,
    '["Planck''s energy equation: E = h * v", "de Broglie wavelength: lambda = h / (m * v)", "Maximum electrons in shell: 2n^2", "Heisenberg Uncertainty Principle: dx * dp >= h / 4pi"]'::jsonb),

    -- Grade 10 Mathematics Unit 1
    (10, 'Mathematics', 1, 'Polynomial Functions (ፖሊኖሚያል ፈንክሽኖች)',
    'A polynomial function is a function of the form f(x) = a_n*x^n + ... + a_0. This unit covers synthetic division, remainder and factor theorems, and finding rational zeros.',
    'ይህ ምዕራፍ ስለ ፖሊኖሚያል ፈንክሽኖች፣ የባለብዙ-ተርም ስሌቶች፣ ሲንቴቲክ ሲንቴቲክ አካፋፈል (Synthetic Division)፣ የቀሪ ቲዎረምና የፋክተር ቲዎረም (Remainder & Factor Theorems) እና የፈንክሽኖቹን ዜሮዎች ስለማውጣት ያስተምራል።',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 1.45, 1, 1,
    '["The degree of a polynomial is the highest power of x.", "Remainder Theorem: If f(x) is divided by x - c, the remainder is f(c).", "Factor Theorem: x - c is a factor of f(x) if and only if f(c) = 0."]'::jsonb,
    '["General Polynomial Form: f(x) = a_n * x^n + a_{n-1} * x^{n-1} + ... + a_0", "Remainder Theorem Form: f(x) = (x - c)q(x) + f(c)", "Synthetic Division Coefficients Matrix"]'::jsonb),

    -- Grade 9 Biology Unit 1
    (9, 'Biology', 1, 'Introduction to Biology and Cell Study (የባዮሎጂ መግቢያና የሴል ጥናት)',
    'Biology is the study of life. Unit 1 explores branches of biology, microscopic techniques, and cell structures including comparison between prokaryotes and eukaryotes.',
    'ባዮሎጂ ስለ ህይወት እና ህይወት ያላቸው ነገሮች የሚያጠና የሳይንስ ዘርፍ ነው። ይህ ምዕራፍ የባዮሎጂን ቅርንጫፎች፣ የማይክሮስኮፕ አጠቃቀምን፣ እንዲሁም የፕሮካርዮቲክና ዩካርዮቲክ ሴሎችን መዋቅርና ልዩነት በዝርዝር ያሳያል።',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 2.80, 1, 1,
    '["Cells are the basic structural and functional unit of life.", "Prokaryotic cells lack a membrane-bound nucleus (e.g. Bacteria).", "Eukaryotic cells have a true nucleus and organelles.", "Mitochondria is the power house of the cell generating ATP."]'::jsonb,
    '["Total Magnification = Eyepiece Lens Mag * Objective Lens Mag", "Cell Theory Principles", "Prokaryotic vs Eukaryotic organelles comparison matrix"]'::jsonb)
ON CONFLICT (id) DO NOTHING;

