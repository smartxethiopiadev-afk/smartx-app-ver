-- =====================================================================
-- SMART LEARN ETHIOPIAN - SEED DATA FOR STUDENTS & QUESTIONS
-- =====================================================================
-- Contains:
-- 1. Sample Packages (Grade 9-12 Premium Tiers)
-- 2. Sample Students & Credentials (Free and Unlocked/Premium)
-- 3. Activation Codes for instant testing
-- 4. Exam Mode Questions (Grade 12 Physics, Mathematics - MCQs)
-- 5. Practice Mode Questions (Multiple Choice, True/False, Blank Space, Matching)
-- =====================================================================

-- 1. SEED PACKAGES
INSERT INTO public.packages (id, title, grade, price_etb, description, badge_text, tier, features)
VALUES 
    ('pkg_grade_12_natural', 'Grade 12 Natural Science Complete Pack', 12, 450.00, 'Complete curriculum notes, worksheets, direct video stream, and Matric preparation exams for Grade 12 Natural Science subjects.', 'Best Seller', 'stream_or_grade', '["Physics Notes & Videos", "Mathematics Advanced Topics", "Chemistry Detailed Explanations", "Biology Practice Sets", "Unlimited Matric Exam Mode & Practice Mode"]'::jsonb),
    ('pkg_grade_12_social', 'Grade 12 Social Science Complete Pack', 12, 450.00, 'Complete curriculum notes, worksheets, and Matric preparation exams for Grade 12 Social Science subjects.', 'Popular', 'stream_or_grade', '["History Complete Units", "Geography Notes & Quizzes", "Economics In-Depth Analysis", "English Matric Prep", "Unlimited Exam & Practice Mode"]'::jsonb),
    ('pkg_grade_11_natural', 'Grade 11 Natural Science Complete Pack', 11, 400.00, 'Comprehensive coverage of Grade 11 Natural Science with step-by-step math and physics solutions.', 'Excellent Choice', 'stream_or_grade', '["Physics Video Lessons", "Mathematics Foundations", "Chemistry Unit Exercises", "Biology Interactive Tests"]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 2. SEED STUDENTS (Primary Source of Truth for Subscription/Device locking)
INSERT INTO public.students (id, phone_number, full_name, grade, stream, device_id, unlocked_packages, subscription_status, subscription_expires_at, is_active)
VALUES 
    -- A Premium Student with all packages unlocked and active subscription
    ('99999999-9999-4999-a999-999999999999', '+251911223344', 'Almaz Tolosa', 12, 'Natural', 'DEVICE_ALMAZ_123', ARRAY['pkg_grade_12_natural', 'pkg_grade_11_natural'], 'active', now() + INTERVAL '365 days', true),
    -- A Free Student with no packages unlocked (gets redirected to paywall/upgrade screen on unit 2+)
    ('88888888-8888-4888-b888-888888888888', '+251922334455', 'Bekele Kebede', 12, 'Natural', 'DEVICE_BEKELE_456', '{}', 'free', NULL, true)
ON CONFLICT (phone_number) DO UPDATE SET
    unlocked_packages = EXCLUDED.unlocked_packages,
    subscription_status = EXCLUDED.subscription_status,
    subscription_expires_at = EXCLUDED.subscription_expires_at;

-- 3. SEED STUDENT CREDENTIALS (Secure login details mapped by phone number)
-- Preloaded password is '123456' or 'smartpass' (for local testing credentials)
INSERT INTO public.student_credentials (id, full_name, phone_number, password, package_id, device_id, is_active)
VALUES 
    ('11111111-1111-4111-b111-111111111111', 'Almaz Tolosa', '+251911223344', '123456', 'pkg_grade_12_natural', 'DEVICE_ALMAZ_123', true),
    ('22222222-2222-4222-b222-222222222222', 'Bekele Kebede', '+251922334455', '123456', NULL, 'DEVICE_BEKELE_456', true)
ON CONFLICT (phone_number) DO NOTHING;

-- 4. SEED ACTIVATION CODES FOR QUICK UNLOCK TESTING
INSERT INTO public.activation_codes (code, package_id, grade, subject, duration_days, is_used)
VALUES 
    ('SMART-G12NAT-777', 'pkg_grade_12_natural', 12, NULL, 365, false),
    ('SMART-G12SOC-888', 'pkg_grade_12_social', 12, NULL, 365, false),
    ('FREE-MATH-101', 'pkg_grade_12_natural', 12, 'Mathematics', 30, false)
ON CONFLICT (code) DO NOTHING;


-- =====================================================================
-- 5. EXAM MODE QUESTIONS (MULTIPLE CHOICE ONLY - Timed National Matric Style)
-- Mapped with correct options (A, B, C, D) and explanations.
-- =====================================================================

-- Grade 12 Physics National Matric Questions
INSERT INTO public.exam_questions (
    id, grade, subject, unit_number, year, exam_category, question_number, question_text, 
    option_a, option_b, option_c, option_d, options, correct_option, correct_answer, explanation, time_limit_seconds, difficulty
)
VALUES 
    (
        'e0011111-1111-4111-a111-000000000001', 
        12, 
        'Physics', 
        1, -- Unit 1: Thermodynamics
        '2016 E.C.', 
        'national_exam', 
        1, 
        'An ideal gas undergoes an isothermal expansion. Which of the following is true about this thermodynamic process?',
        'The internal energy of the gas increases.',
        'The heat absorbed by the gas is completely converted into work done by the gas.',
        'No heat exchange takes place between the gas and its surroundings.',
        'The work done on the gas is equal to the temperature change.',
        '[
            {"key": "A", "text": "The internal energy of the gas increases."},
            {"key": "B", "text": "The heat absorbed by the gas is completely converted into work done by the gas."},
            {"key": "C", "text": "No heat exchange takes place between the gas and its surroundings."},
            {"key": "D", "text": "The work done on the gas is equal to the temperature change."}
        ]'::jsonb,
        'B',
        'B',
        'In an isothermal process, the temperature remains constant (ΔT = 0), which means the change in internal energy is zero (ΔU = 0). According to the first law of thermodynamics (Q = ΔU + W), the net heat absorbed (Q) is equal to the work done by the gas (W). Therefore, all absorbed heat is converted into work.',
        90,
        'medium'
    ),
    (
        'e0011111-1111-4111-a111-000000000002', 
        12, 
        'Physics', 
        1,
        '2015 E.C.', 
        'national_exam', 
        2, 
        'What is the efficiency of a Carnot engine operating between a hot reservoir at 600 K and a cold reservoir at 300 K?',
        '25%',
        '33.3%',
        '50%',
        '100%',
        '[
            {"key": "A", "text": "25%"},
            {"key": "B", "text": "33.3%"},
            {"key": "C", "text": "50%"},
            {"key": "D", "text": "100%"}
        ]'::jsonb,
        'C',
        'C',
        'The maximum theoretical efficiency of a heat engine is given by the Carnot efficiency formula: η = 1 - (Tc / Th). Substituting the given values: η = 1 - (300 K / 600 K) = 1 - 0.5 = 0.5, which is equal to 50%.',
        90,
        'easy'
    ),
    -- Grade 12 Mathematics Advanced Questions
    (
        'e0011111-1111-4111-a111-000000000003', 
        12, 
        'Mathematics', 
        1, -- Unit 1: Sequences and Series
        '2016 E.C.', 
        'national_exam', 
        1, 
        'What is the sum of the infinite geometric series: 10 + 5 + 2.5 + 1.25 + ...?',
        '15',
        '20',
        '25',
        'The series diverges and does not have a finite sum.',
        '[
            {"key": "A", "text": "15"},
            {"key": "B", "text": "20"},
            {"key": "C", "text": "25"},
            {"key": "D", "text": "The series diverges and does not have a finite sum."}
        ]'::jsonb,
        'B',
        'B',
        'The given series is a geometric series with the first term a = 10 and common ratio r = 5 / 10 = 0.5. Since the absolute value of r is less than 1 (|0.5| < 1), the sum of the infinite geometric series converges and is given by: S = a / (1 - r) = 10 / (1 - 0.5) = 10 / 0.5 = 20.',
        120,
        'medium'
    )
ON CONFLICT (id) DO NOTHING;


-- =====================================================================
-- 6. PRACTICE MODE QUESTIONS (Multi-Format Learning)
-- Supports multiple_choice, true_false, blank_space, and matching.
-- =====================================================================

-- Type A: Practice - Multiple Choice (Grade 12 Physics)
INSERT INTO public.practice_questions (
    id, grade, subject, unit_number, topic, question_type, question_number, question_text, 
    options, correct_answer, hint, explanation, difficulty
)
VALUES 
    (
        'p0011111-1111-4111-b111-000000000001',
        12,
        'Physics',
        1,
        'Thermodynamic Laws',
        'multiple_choice',
        1,
        'Which thermodynamic law states that "It is impossible to build a device that operates in a cycle and produces no other effect than the transfer of heat from a lower-temperature body to a higher-temperature body"?',
        '[
            {"key": "A", "text": "The Zeroth Law of Thermodynamics", "is_correct": false},
            {"key": "B", "text": "The First Law of Thermodynamics", "is_correct": false},
            {"key": "C", "text": "The Second Law of Thermodynamics (Clausius Statement)", "is_correct": true},
            {"key": "D", "text": "The Third Law of Thermodynamics", "is_correct": false}
        ]'::jsonb,
        'C',
        'Think about the flow of heat and entropy statements regarding refrigerators and engines.',
        'This statement is known as the Clausius Statement of the Second Law of Thermodynamics. It establishes that heat cannot spontaneously flow from a colder reservoir to a hotter reservoir without external work being input into the system.',
        'medium'
    )
ON CONFLICT (id) DO NOTHING;

-- Type B: Practice - True / False (እውነት / ሐሰት)
INSERT INTO public.practice_questions (
    id, grade, subject, unit_number, topic, question_type, question_number, question_text, 
    correct_boolean, correct_answer, hint, explanation, difficulty
)
VALUES 
    (
        'p0011111-1111-4111-b111-000000000002',
        12,
        'Physics',
        1,
        'Thermodynamic Work',
        'true_false',
        2,
        'In an isobaric process, the pressure of the system remains perfectly constant while its volume changes.',
        true,
        'True',
        'Iso- means equal, and -baric relates to barometric pressure.',
        'Yes, an isobaric process is a thermodynamic process in which the pressure remains constant. The formula for the work done is W = P * ΔV, where pressure P is a constant value.',
        'easy'
    ),
    (
        'p0011111-1111-4111-b111-000000000003',
        12,
        'Physics',
        1,
        'Entropy',
        'true_false',
        3,
        'According to the Second Law of Thermodynamics, the total entropy of an isolated system can decrease over time.',
        false,
        'False',
        'Isolated systems always move towards higher states of disorder.',
        'The second law of thermodynamics asserts that the total entropy of any isolated system can never decrease over time; it can only remain constant or increase in natural thermodynamic processes.',
        'medium'
    )
ON CONFLICT (id) DO NOTHING;

-- Type C: Practice - Blank Space (Fill in the Blanks with accepted variants)
INSERT INTO public.practice_questions (
    id, grade, subject, unit_number, topic, question_type, question_number, question_text, 
    blank_answer, accepted_answers, case_sensitive, correct_answer, hint, explanation, difficulty
)
VALUES 
    (
        'p0011111-1111-4111-b111-000000000004',
        12,
        'Physics',
        1,
        'Thermodynamics Foundations',
        'blank_space',
        4,
        'The process in which there is no heat exchange whatsoever between the system and its surroundings (Q = 0) is called an ________ process.',
        'adiabatic',
        '["adiabatic", "Adiabatic", "adiabatik", "አዲያባቲክ"]'::jsonb,
        false,
        'adiabatic',
        'Starts with letter "a", describes total insulation.',
        'An adiabatic process is one in which no heat enters or leaves the system (Q = 0). It typically occurs when a system is highly insulated or when the process happens extremely rapidly (e.g., sound propagation).',
        'medium'
    )
ON CONFLICT (id) DO NOTHING;

-- Type D: Practice - Matching (አዛምድ - Matching terms with their descriptions)
INSERT INTO public.practice_questions (
    id, grade, subject, unit_number, topic, question_type, question_number, question_text, 
    matching_pairs, correct_answer, hint, explanation, difficulty
)
VALUES 
    (
        'p0011111-1111-4111-b111-000000000005',
        12,
        'Physics',
        1,
        'Thermodynamic Terminology',
        'matching',
        5,
        'Match each thermodynamic process with its corresponding constant state variable.',
        '[
            {"left": "Isothermal Process", "right": "Constant Temperature (T = constant)"},
            {"left": "Isobaric Process", "right": "Constant Pressure (P = constant)"},
            {"left": "Isochoric Process", "right": "Constant Volume (V = constant)"},
            {"left": "Adiabatic Process", "right": "No Heat Exchange (Q = 0)"}
        ]'::jsonb,
        'Isothermal -> Constant Temperature, Isobaric -> Constant Pressure, Isochoric -> Constant Volume, Adiabatic -> Q = 0',
        'Use suffixes like -thermal (temperature), -baric (pressure), -choric (volume).',
        'Here are the descriptions:\n1. Isothermal processes maintain constant temperature (ΔT=0).\n2. Isobaric processes maintain constant pressure (ΔP=0).\n3. Isochoric processes maintain constant volume (ΔV=0, hence work done is 0).\n4. Adiabatic processes feature no heat transfer (Q=0).',
        'easy'
    )
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- SEEDING SUCCESS CONFIRMATION QUERY
-- =====================================================================
SELECT 
    (SELECT COUNT(*) FROM public.packages) as total_packages,
    (SELECT COUNT(*) FROM public.students) as total_students,
    (SELECT COUNT(*) FROM public.activation_codes) as total_activation_codes,
    (SELECT COUNT(*) FROM public.exam_questions) as total_exam_questions,
    (SELECT COUNT(*) FROM public.practice_questions) as total_practice_questions;
