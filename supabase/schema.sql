-- ==============================================================================
-- SMART X ETHIOPIA - COMPLETE SUPABASE DATABASE SCHEMA & SQL FORMS
-- 1. short_notes (Formatted Chapter Overviews & Key Formulas)
-- 2. worksheets (Unit Practice Sheets, Model Questions & Exercises)
-- 3. unit_downloads (Download tracking per user/device & aggregate statistics)
-- 4. active_user_sessions (Real-time active user telemetry & heartbeat tracker)
-- 5. question_reports (Student error reporting with Telegram sync)
-- 6. user_feedback (Ratings, Suggestions & App reviews)
-- 7. questions & question_options (MCQs)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: short_notes
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.short_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INTEGER NOT NULL CHECK (grade IN (9, 10, 11, 12)),
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    html_content TEXT NOT NULL,
    estimated_read_minutes INTEGER DEFAULT 15,
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT uq_short_notes_grade_subject_unit UNIQUE (grade, subject, unit_number)
);

CREATE INDEX IF NOT EXISTS idx_short_notes_lookup 
ON public.short_notes (grade, subject, unit_number);

ALTER TABLE public.short_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on short_notes" ON public.short_notes FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert/update on short_notes" ON public.short_notes FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 2. Table: worksheets
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.worksheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INTEGER NOT NULL CHECK (grade IN (9, 10, 11, 12)),
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    am_title TEXT NOT NULL,
    description TEXT NOT NULL,
    total_questions INTEGER DEFAULT 15,
    download_count INTEGER DEFAULT 0,
    difficulty TEXT DEFAULT 'Medium' CHECK (difficulty IN ('Easy', 'Medium', 'Hard', 'National Exam Standard')),
    key_topics TEXT[] DEFAULT '{}',
    file_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT uq_worksheets_grade_subject_unit UNIQUE (grade, subject, unit_number)
);

CREATE INDEX IF NOT EXISTS idx_worksheets_lookup 
ON public.worksheets (grade, subject, unit_number);

ALTER TABLE public.worksheets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on worksheets" ON public.worksheets FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert/update on worksheets" ON public.worksheets FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 3. Table: unit_downloads (Download Analytics)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.unit_downloads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    student_name TEXT,
    student_phone TEXT,
    grade INTEGER NOT NULL,
    subject TEXT NOT NULL,
    unit_id TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    download_type TEXT NOT NULL DEFAULT 'short_note' CHECK (download_type IN ('short_note', 'worksheet', 'quiz', 'full_bundle')),
    app_version TEXT DEFAULT '1.0.2',
    downloaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_unit_downloads_unit ON public.unit_downloads (unit_id);
CREATE INDEX IF NOT EXISTS idx_unit_downloads_device ON public.unit_downloads (device_id);
CREATE INDEX IF NOT EXISTS idx_unit_downloads_grade_subj ON public.unit_downloads (grade, subject);

ALTER TABLE public.unit_downloads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public insert on unit_downloads" ON public.unit_downloads FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public read on unit_downloads" ON public.unit_downloads FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 4. Table: active_user_sessions (Real-time Active Users Telemetry)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.active_user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL UNIQUE,
    user_name TEXT,
    phone_number TEXT,
    grade INTEGER,
    app_version TEXT DEFAULT '1.0.2',
    platform TEXT DEFAULT 'android',
    last_active_at TIMESTAMPTZ DEFAULT now(),
    total_sessions INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_active_sessions_last_active ON public.active_user_sessions (last_active_at);

ALTER TABLE public.active_user_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public insert/update on active_user_sessions" 
ON public.active_user_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read on active_user_sessions" 
ON public.active_user_sessions FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 5. Table: question_reports (Error Reporting with Telegram Link)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.question_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id TEXT NOT NULL,
    unit_id TEXT NOT NULL,
    question_text TEXT NOT NULL,
    reason TEXT NOT NULL,
    student_name TEXT,
    student_phone TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_question_reports_unit ON public.question_reports (unit_id);

ALTER TABLE public.question_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public insert on question_reports" ON public.question_reports FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public read on question_reports" ON public.question_reports FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 6. Table: user_feedback
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_name TEXT,
    phone_number TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    category TEXT NOT NULL CHECK (category IN ('Curriculum/Content', 'App Feature', 'Bug Report', 'Worksheet Request', 'General')),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public insert on user_feedback" ON public.user_feedback FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public read on user_feedback" ON public.user_feedback FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 7. Table: questions & question_options
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id TEXT NOT NULL,
    question_text TEXT NOT NULL,
    question_number INTEGER,
    order_index INTEGER,
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_questions_unit ON public.questions (unit_id, order_index);

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on questions" ON public.questions FOR SELECT USING (true);

CREATE TABLE IF NOT EXISTS public.question_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT false,
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_options_question_id ON public.question_options (question_id);

ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on question_options" ON public.question_options FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 8. HELPER RPC FUNCTIONS (Analytics & Counters)
-- ------------------------------------------------------------------------------

-- Function to record user heartbeat and keep active user count fresh
CREATE OR REPLACE FUNCTION public.ping_active_session(
    p_device_id TEXT,
    p_user_name TEXT,
    p_phone TEXT,
    p_grade INTEGER,
    p_app_version TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.active_user_sessions (
        device_id, user_name, phone_number, grade, app_version, last_active_at, total_sessions
    ) VALUES (
        p_device_id, p_user_name, p_phone, p_grade, p_app_version, now(), 1
    )
    ON CONFLICT (device_id) DO UPDATE SET
        user_name = COALESCE(EXCLUDED.user_name, public.active_user_sessions.user_name),
        phone_number = COALESCE(EXCLUDED.phone_number, public.active_user_sessions.phone_number),
        grade = COALESCE(EXCLUDED.grade, public.active_user_sessions.grade),
        app_version = EXCLUDED.app_version,
        last_active_at = now(),
        total_sessions = public.active_user_sessions.total_sessions + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log download and increment counter
CREATE OR REPLACE FUNCTION public.record_unit_download(
    p_device_id TEXT,
    p_user_name TEXT,
    p_phone TEXT,
    p_grade INTEGER,
    p_subject TEXT,
    p_unit_id TEXT,
    p_unit_number INTEGER,
    p_type TEXT
)
RETURNS VOID AS $$
BEGIN
    -- 1. Insert download log
    INSERT INTO public.unit_downloads (
        device_id, student_name, student_phone, grade, subject, unit_id, unit_number, download_type
    ) VALUES (
        p_device_id, p_user_name, p_phone, p_grade, p_subject, p_unit_id, p_unit_number, p_type
    );

    -- 2. Increment counter on short_notes or worksheets
    IF p_type = 'short_note' THEN
        UPDATE public.short_notes 
        SET download_count = download_count + 1 
        WHERE grade = p_grade AND ilike(subject, p_subject) AND unit_number = p_unit_number;
    ELSIF p_type = 'worksheet' THEN
        UPDATE public.worksheets 
        SET download_count = download_count + 1 
        WHERE grade = p_grade AND ilike(subject, p_subject) AND unit_number = p_unit_number;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 9. SAMPLE SQL FORMS (Ready to Copy/Insert for Short Notes & Worksheets)
-- ------------------------------------------------------------------------------

-- Sample Short Notes
INSERT INTO public.short_notes (grade, subject, unit_number, title, html_content, estimated_read_minutes, download_count)
VALUES 
(
    11,
    'mathematics',
    1,
    'Relations and Functions Cheatsheet',
    '<h2>Unit 1: Relations & Functions</h2>
    <div class="callout"><strong>Core Concept:</strong> Relations, Functions, One-to-One, Onto, Inverse, and Domain/Range analysis.</div>
    <h3>1. Invertibility Rule</h3>
    <p>A function f(x) has an inverse f<sup>-1</sup>(x) if and only if it is a <strong>bijective</strong> (both one-to-one and onto) function.</p>
    <div class="formula">(f &omicron; f<sup>-1</sup>)(x) = x and (f<sup>-1</sup> &omicron; f)(x) = x</div>',
    20,
    142
),
(
    11,
    'physics',
    1,
    'Vectors and Physical Quantities Summary',
    '<h2>Unit 1: Vectors and Physical Quantities</h2>
    <div class="callout"><strong>Core Focus:</strong> Fundamental units, vector components, dot & cross products, and measurement uncertainty.</div>
    <h3>1. Base SI Units</h3>
    <p>Physical quantities are classified into base and derived units.</p>
    <div class="formula">|A| = &radic;(A<sub>x</sub><sup>2</sup> + A<sub>y</sub><sup>2</sup>)</div>',
    25,
    318
),
(
    12,
    'biology',
    1,
    'Applications of Biotechnology in Ethiopia',
    '<h2>Unit 1: Biotechnology</h2>
    <div class="callout"><strong>Key Focus:</strong> Recombinant DNA technology, PCR amplification, and tissue culture applications in agriculture.</div>
    <h3>1. Recombinant DNA</h3>
    <p>Restriction enzymes act as molecular scissors cutting DNA at palindromic recognition sequences.</p>',
    22,
    189
)
ON CONFLICT (grade, subject, unit_number) DO NOTHING;

-- Sample Worksheets
INSERT INTO public.worksheets (grade, subject, unit_number, title, am_title, description, total_questions, download_count, difficulty, key_topics)
VALUES
(
    11,
    'mathematics',
    1,
    'Relations and Functions Master Worksheet',
    'የግንኙነቶችና ፈንክሽኖች ዋና ልምምድ ወረቀት',
    'Standard matric & model exam questions covering inverse functions, composite graphs, and domain restrictions.',
    20,
    87,
    'National Exam Standard',
    ARRAY['Domain & Range', 'Bijective Functions', 'Composite Operations', 'Inverse Graphs']
),
(
    11,
    'mathematics',
    2,
    'Rational Expressions & Asymptotes Drill',
    'የአመክንዮአዊ መግለጫዎች የፈተና ልምምድ',
    'Intensive exercises on partial fractions, vertical & slant asymptotes, and inequality solutions.',
    15,
    64,
    'Medium',
    ARRAY['Vertical Asymptotes', 'Horizontal Limits', 'Partial Fractions']
),
(
    11,
    'physics',
    1,
    'Vectors and Mechanics Practice Sheet',
    'የቬክተሮችና መካኒክስ ሞዴል ጥያቄዎች',
    'Problem set for resolving 3D vectors, calculating scalar products, vector projections, and relative velocity.',
    25,
    215,
    'National Exam Standard',
    ARRAY['Dot Product', 'Cross Product', 'Vector Components', 'Relative Velocity']
),
(
    11,
    'biology',
    1,
    'Science of Biology & Lab Techniques Worksheet',
    'የሥነ-ሕይወት ሳይንስና የላቦራቶሪ ጥያቄዎች',
    'Multiple choice and structured questions on scientific methods, microscopy, and biological tools.',
    18,
    93,
    'Easy',
    ARRAY['Microscopy', 'Scientific Method', 'Centrifugation', 'Electrophoresis']
),
(
    12,
    'physics',
    1,
    'Thermodynamics and Heat Engines Worksheet',
    'የቴርሞዳይናሚክስ እና ኢንጅን ልምምድ ወረቀት',
    'In-depth numerical problems on Carnot efficiency, adiabatic processes, entropy changes, and heat capacities.',
    20,
    112,
    'National Exam Standard',
    ARRAY['First Law', 'Second Law', 'Carnot Cycle', 'Entropy']
)
ON CONFLICT (grade, subject, unit_number) DO NOTHING;
