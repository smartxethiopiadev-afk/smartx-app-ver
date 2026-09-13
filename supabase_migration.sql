-- ============================================================================
-- SMART X ETHIOPIAN LEARNING APP: DATABASE SCHEMA MIGRATION
-- Packages, Worksheets, User Subscriptions & Row Level Security (RLS)
-- ============================================================================

-- 1. PACKAGES TABLE
-- Holds available curriculum packages (Grade 9 to 12) with pricing and descriptions
CREATE TABLE IF NOT EXISTS public.packages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    grade INTEGER NOT NULL CHECK (grade BETWEEN 9 AND 12),
    price_etb NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    description TEXT,
    badge_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. WORKSHEETS TABLE
-- Holds unit worksheets with rich HTML/formula questions and solutions
CREATE TABLE IF NOT EXISTS public.worksheets (
    id TEXT PRIMARY KEY,
    grade INTEGER NOT NULL CHECK (grade BETWEEN 9 AND 12),
    subject TEXT NOT NULL,
    unit_number INTEGER NOT NULL CHECK (unit_number >= 1),
    title TEXT NOT NULL,
    questions_html TEXT NOT NULL,
    solutions_html TEXT NOT NULL,
    package_id TEXT REFERENCES public.packages(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. USER SUBSCRIPTIONS TABLE
-- Tracks unlocked packages per student phone number
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    package_id TEXT NOT NULL REFERENCES public.packages(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_packages_grade ON public.packages (grade);
CREATE INDEX IF NOT EXISTS idx_worksheets_lookup ON public.worksheets (grade, subject, unit_number);
CREATE INDEX IF NOT EXISTS idx_worksheets_package ON public.worksheets (package_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_phone ON public.user_subscriptions (phone_number, package_id);

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worksheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Clean up existing policies if re-running migration
DROP POLICY IF EXISTS "Allow public read access on packages" ON public.packages;
DROP POLICY IF EXISTS "Allow public read access on worksheets" ON public.worksheets;
DROP POLICY IF EXISTS "Allow users to read own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Allow insertion of subscriptions" ON public.user_subscriptions;

-- Packages: Public read access
CREATE POLICY "Allow public read access on packages"
    ON public.packages FOR SELECT
    TO public
    USING (true);

-- Worksheets: Public read access (Unit 1 free for all; client/backend verify subscription for Unit 2+)
CREATE POLICY "Allow public read access on worksheets"
    ON public.worksheets FOR SELECT
    TO public
    USING (true);

-- Subscriptions: Read access for users
CREATE POLICY "Allow users to read own subscriptions"
    ON public.user_subscriptions FOR SELECT
    TO public
    USING (true);

-- Subscriptions: Insert access for activations
CREATE POLICY "Allow insertion of subscriptions"
    ON public.user_subscriptions FOR INSERT
    TO public
    WITH CHECK (true);

-- ============================================================================
-- 6. SAMPLE SEED DATA FOR GRADES 9–12 PACKAGES
-- ============================================================================
INSERT INTO public.packages (id, title, grade, price_etb, description, badge_text)
VALUES
    (
        'pkg_grade_9',
        'Grade 9 Ultimate Foundation & Exam Prep',
        9,
        299.00,
        'Complete access to all Grade 9 units (Units 1–9) across Mathematics, Physics, Chemistry, and Biology. Includes short notes, practice worksheets with step-by-step solutions, and interactive chapter quizzes.',
        'MOST POPULAR'
    ),
    (
        'pkg_grade_10',
        'Grade 10 National Exam (EGSECE) Booster',
        10,
        349.00,
        'Comprehensive Ethiopian General Secondary Education Certificate Examination toolkit. Contains all unit worksheets, solved model exams, formula sheets, and offline mastery tests.',
        'EXAM ESSENTIAL'
    ),
    (
        'pkg_grade_11',
        'Grade 11 Natural & Social Sciences Mastery',
        11,
        399.00,
        'Full university-preparatory package for Grade 11 students. Advanced practice problems, calculus & trigonometry worksheets, chemistry reaction guides, and past regional tests.',
        'ADVANCED'
    ),
    (
        'pkg_grade_12',
        'Grade 12 University Entrance (EUEE) Master Package',
        12,
        499.00,
        'The ultimate Ethiopian University Entrance Examination preparation kit. Past 10 years matric exam questions solved step-by-step, all unit notes, formula flashcards, and priority Telegram tutor support.',
        'BEST VALUE'
    )
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    grade = EXCLUDED.grade,
    price_etb = EXCLUDED.price_etb,
    description = EXCLUDED.description,
    badge_text = EXCLUDED.badge_text;

-- ============================================================================
-- 7. SAMPLE SEED DATA FOR WORKSHEETS (GRADES 9–12)
-- ============================================================================

-- Grade 9 Mathematics - Unit 1 (FREE)
INSERT INTO public.worksheets (id, grade, subject, unit_number, title, questions_html, solutions_html, package_id)
VALUES (
    'ws_g9_math_u1',
    9,
    'Mathematics',
    1,
    'Unit 1: Further on Sets - Practice Worksheet',
    '<div class="question" data-number="1">
        <h3>Question 1</h3>
        <p>Let $A = \{1, 2, 3, 4, 5\}$ and $B = \{3, 4, 5, 6, 7\}$.</p>
        <p>Find the symmetric difference $A \Delta B$ and the Cartesian product cardinality $n(A \times B)$.</p>
    </div>
    <div class="question" data-number="2">
        <h3>Question 2</h3>
        <p>In a class of 50 students, 30 study Mathematics, 25 study Physics, and 10 study neither subject.</p>
        <p>How many students study <strong>both</strong> Mathematics and Physics?</p>
    </div>
    <div class="question" data-number="3">
        <h3>Question 3</h3>
        <p>If $U = \{x \in \mathbb{N} : 1 \le x \le 20\}$, $P = \{x : x \text{ is prime}\}$, and $E = \{x : x \text{ is even}\}$.</p>
        <p>Determine $(P \cup E)''$ (the complement of the union).</p>
    </div>',
    '<div class="solution" data-number="1">
        <h4>Solution for Question 1:</h4>
        <p><strong>Step 1:</strong> Find the symmetric difference $A \Delta B = (A \setminus B) \cup (B \setminus A)$.</p>
        <p>$A \setminus B = \{1, 2\}$</p>
        <p>$B \setminus A = \{6, 7\}$</p>
        <p>Thus, $A \Delta B = \{1, 2, 6, 7\}$.</p>
        <p><strong>Step 2:</strong> Cardinality of Cartesian product: $n(A \times B) = n(A) \times n(B) = 5 \times 5 = 25$.</p>
    </div>
    <div class="solution" data-number="2">
        <h4>Solution for Question 2:</h4>
        <p><strong>Step 1:</strong> Total students $n(U) = 50$. Students studying at least one subject: $n(M \cup P) = 50 - 10 = 40$.</p>
        <p><strong>Step 2:</strong> Use the principle of inclusion-exclusion:</p>
        <p>$$n(M \cup P) = n(M) + n(P) - n(M \cap P)$$</p>
        <p>$$40 = 30 + 25 - n(M \cap P) = 55 - n(M \cap P)$$</p>
        <p>$$n(M \cap P) = 55 - 40 = 15$$</p>
        <p><strong>Answer:</strong> 15 students study both subjects.</p>
    </div>
    <div class="solution" data-number="3">
        <h4>Solution for Question 3:</h4>
        <p>Prime numbers $\le 20$: $P = \{2, 3, 5, 7, 11, 13, 17, 19\}$.</p>
        <p>Even numbers $\le 20$: $E = \{2, 4, 6, 8, 10, 12, 14, 16, 18, 20\}$.</p>
        <p>$P \cup E$ contains all even numbers plus odd primes $\{3, 5, 7, 11, 13, 17, 19\}$.</p>
        <p>The complement $(P \cup E)''$ in $U$ is the set of odd composite numbers up to 20 plus 1:</p>
        <p>$(P \cup E)'' = \{1, 9, 15\}$.</p>
    </div>',
    'pkg_grade_9'
) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    questions_html = EXCLUDED.questions_html,
    solutions_html = EXCLUDED.solutions_html;

-- Grade 9 Mathematics - Unit 2 (LOCKED / PREMIUM)
INSERT INTO public.worksheets (id, grade, subject, unit_number, title, questions_html, solutions_html, package_id)
VALUES (
    'ws_g9_math_u2',
    9,
    'Mathematics',
    2,
    'Unit 2: The Number System - Advanced Worksheet',
    '<div class="question" data-number="1">
        <h3>Question 1</h3>
        <p>Simplify the radical expression: $\sqrt{75} - \sqrt{48} + \sqrt{108}$.</p>
    </div>
    <div class="question" data-number="2">
        <h3>Question 2</h3>
        <p>Rationalize the denominator of $\frac{4}{3 - \sqrt{5}}$.</p>
    </div>
    <div class="question" data-number="3">
        <h3>Question 3</h3>
        <p>Convert the repeating decimal $0.\overline{36} = 0.363636\dots$ into a simplified fraction $\frac{a}{b}$.</p>
    </div>',
    '<div class="solution" data-number="1">
        <h4>Solution for Question 1:</h4>
        <p>Factorize inside the radicals:</p>
        <p>$\sqrt{75} = \sqrt{25 \cdot 3} = 5\sqrt{3}$</p>
        <p>$\sqrt{48} = \sqrt{16 \cdot 3} = 4\sqrt{3}$</p>
        <p>$\sqrt{108} = \sqrt{36 \cdot 3} = 6\sqrt{3}$</p>
        <p>Combine like radicals: $(5 - 4 + 6)\sqrt{3} = 7\sqrt{3}$.</p>
    </div>
    <div class="solution" data-number="2">
        <h4>Solution for Question 2:</h4>
        <p>Multiply numerator and denominator by conjugate $(3 + \sqrt{5})$:</p>
        <p>$$\frac{4(3 + \sqrt{5})}{(3 - \sqrt{5})(3 + \sqrt{5})} = \frac{12 + 4\sqrt{5}}{9 - 5} = \frac{12 + 4\sqrt{5}}{4} = 3 + \sqrt{5}$$</p>
    </div>
    <div class="solution" data-number="3">
        <h4>Solution for Question 3:</h4>
        <p>Let $x = 0.3636\dots$</p>
        <p>$100x = 36.3636\dots$</p>
        <p>$100x - x = 99x = 36 \implies x = \frac{36}{99} = \frac{4}{11}$.</p>
    </div>',
    'pkg_grade_9'
) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    questions_html = EXCLUDED.questions_html,
    solutions_html = EXCLUDED.solutions_html;

-- Grade 10 Physics - Unit 1 (FREE)
INSERT INTO public.worksheets (id, grade, subject, unit_number, title, questions_html, solutions_html, package_id)
VALUES (
    'ws_g10_phys_u1',
    10,
    'Physics',
    1,
    'Unit 1: Motion in Two Dimensions - Practice Worksheet',
    '<div class="question" data-number="1">
        <h3>Question 1</h3>
        <p>A projectile is launched from ground level with an initial speed of $v_0 = 20\text{ m/s}$ at an angle of $\theta = 30^\circ$ above the horizontal. Assuming $g = 10\text{ m/s}^2$ and negligible air resistance:</p>
        <p>(a) Calculate the time to reach maximum height.<br/>(b) Find the maximum height reached.</p>
    </div>
    <div class="question" data-number="2">
        <h3>Question 2</h3>
        <p>A particle moves in a horizontal circular path of radius $r = 4\text{ m}$ with a constant speed $v = 8\text{ m/s}$.</p>
        <p>Determine its centripetal acceleration $a_c$ and period of revolution $T$.</p>
    </div>',
    '<div class="solution" data-number="1">
        <h4>Solution for Question 1:</h4>
        <p><strong>(a)</strong> Initial vertical velocity $v_{0y} = v_0 \sin(30^\circ) = 20 \times 0.5 = 10\text{ m/s}$.</p>
        <p>Time to top: $t = \frac{v_{0y}}{g} = \frac{10}{10} = 1.0\text{ s}$.</p>
        <p><strong>(b)</strong> Maximum height: $H = \frac{v_{0y}^2}{2g} = \frac{10^2}{2(10)} = \frac{100}{20} = 5\text{ m}$.</p>
    </div>
    <div class="solution" data-number="2">
        <h4>Solution for Question 2:</h4>
        <p><strong>Centripetal acceleration:</strong> $a_c = \frac{v^2}{r} = \frac{8^2}{4} = \frac{64}{4} = 16\text{ m/s}^2$.</p>
        <p><strong>Period:</strong> $T = \frac{2\pi r}{v} = \frac{2 \times 3.1416 \times 4}{8} = \pi \approx 3.14\text{ s}$.</p>
    </div>',
    'pkg_grade_10'
) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    questions_html = EXCLUDED.questions_html,
    solutions_html = EXCLUDED.solutions_html;

-- Grade 12 Mathematics - Unit 1 (FREE)
INSERT INTO public.worksheets (id, grade, subject, unit_number, title, questions_html, solutions_html, package_id)
VALUES (
    'ws_g12_math_u1',
    12,
    'Mathematics',
    1,
    'Unit 1: Sequences and Series - EUEE Model Worksheet',
    '<div class="question" data-number="1">
        <h3>Question 1 (EUEE Prep)</h3>
        <p>The 4th term of an arithmetic progression (AP) is 15 and the 10th term is 39.</p>
        <p>Find the first term $a_1$, the common difference $d$, and the sum of the first 20 terms $S_{20}$.</p>
    </div>
    <div class="question" data-number="2">
        <h3>Question 2</h3>
        <p>Evaluate the infinite geometric series: $\sum_{n=1}^{\infty} 5 \left(\frac{2}{3}\right)^n$.</p>
    </div>',
    '<div class="solution" data-number="1">
        <h4>Solution for Question 1:</h4>
        <p>$a_4 = a_1 + 3d = 15$</p>
        <p>$a_{10} = a_1 + 9d = 39$</p>
        <p>Subtracting: $6d = 24 \implies d = 4$.</p>
        <p>$a_1 = 15 - 3(4) = 15 - 12 = 3$.</p>
        <p>$S_{20} = \frac{20}{2} [2a_1 + (20 - 1)d] = 10 [2(3) + 19(4)] = 10 [6 + 76] = 10(82) = 820$.</p>
    </div>
    <div class="solution" data-number="2">
        <h4>Solution for Question 2:</h4>
        <p>First term $a_1 = 5 \times \frac{2}{3} = \frac{10}{3}$.</p>
        <p>Common ratio $r = \frac{2}{3} < 1$.</p>
        <p>Sum to infinity: $S_{\infty} = \frac{a_1}{1 - r} = \frac{10/3}{1 - 2/3} = \frac{10/3}{1/3} = 10$.</p>
    </div>',
    'pkg_grade_12'
) ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    questions_html = EXCLUDED.questions_html,
    solutions_html = EXCLUDED.solutions_html;
