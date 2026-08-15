-- ==============================================================================
-- Smart X ET - Supabase Database Schema & Sample Data
-- 1. short_notes (HTML/CSS Study Notes)
-- 2. questions & question_options (Categorized & Sequenced MCQs)
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
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_short_notes_lookup 
ON public.short_notes (grade, subject, unit_number);

ALTER TABLE public.short_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on short_notes" 
ON public.short_notes FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert/update on short_notes"
ON public.short_notes FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 2. Tables: questions & question_options
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

CREATE INDEX IF NOT EXISTS idx_questions_unit 
ON public.questions (unit_id, order_index);

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

CREATE INDEX IF NOT EXISTS idx_options_question_id 
ON public.question_options (question_id);

ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on question_options" ON public.question_options FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 3. Sample SQL Form: Short Notes (HTML/CSS Formatted)
-- ------------------------------------------------------------------------------
INSERT INTO public.short_notes (grade, subject, unit_number, title, html_content)
VALUES 
(
    11,
    'physics',
    1,
    'Vectors and Physical Quantities',
    '<h2>Unit 1: Vectors and Physical Quantities</h2>
    <div class="callout">
      <strong>Core Focus:</strong> Fundamental units, vector components, dot & cross products, and measurement uncertainty.
    </div>
    <h3>1. Base SI Units</h3>
    <p>Physical quantities are classified into base and derived units.</p>
    <table>
      <thead>
        <tr><th>Quantity</th><th>Unit</th><th>Symbol</th><th>Dimension</th></tr>
      </thead>
      <tbody>
        <tr><td>Length</td><td>Meter</td><td>m</td><td>[L]</td></tr>
        <tr><td>Mass</td><td>Kilogram</td><td>kg</td><td>[M]</td></tr>
        <tr><td>Time</td><td>Second</td><td>s</td><td>[T]</td></tr>
        <tr><td>Current</td><td>Ampere</td><td>A</td><td>[I]</td></tr>
      </tbody>
    </table>
    <h3>2. Vector Resolution</h3>
    <div class="formula">
      A<sub>x</sub> = |A| &times; cos(&theta;)<br>
      A<sub>y</sub> = |A| &times; sin(&theta;)<br>
      |A| = &radic;(A<sub>x</sub><sup>2</sup> + A<sub>y</sub><sup>2</sup>)
    </div>'
),
(
    12,
    'physics',
    1,
    'Thermodynamics and Heat Engines',
    '<h2>Unit 1: Thermodynamics</h2>
    <div class="callout">
      <strong>Key Concept:</strong> First and Second Laws of Thermodynamics, Carnot cycle, and thermal efficiency.
    </div>
    <h3>1. First Law of Thermodynamics</h3>
    <div class="formula">
      &Delta;U = Q - W
    </div>
    <p>Where <em>&Delta;U</em> is change in internal energy, <em>Q</em> is heat energy added, and <em>W</em> is work done by the system.</p>
    <h3>2. Carnot Efficiency</h3>
    <div class="formula">
      &eta;<sub>Carnot</sub> = 1 - (T<sub>C</sub> / T<sub>H</sub>)
    </div>'
);

-- ------------------------------------------------------------------------------
-- 4. Sample SQL Form: Questions & Options
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    q1_id UUID := gen_random_uuid();
    q2_id UUID := gen_random_uuid();
    q3_id UUID := gen_random_uuid();
BEGIN
    -- Question 1: Physics Grade 11 Unit 1
    INSERT INTO public.questions (id, unit_id, question_text, question_number, order_index, explanation)
    VALUES (
        q1_id,
        '11_physics_unit_1',
        'Which of the following is a fundamental (base) SI unit?',
        1,
        1,
        'The SI base units are meter (m), kilogram (kg), second (s), ampere (A), kelvin (K), mole (mol), and candela (cd). Newton and Joule are derived units.'
    );

    INSERT INTO public.question_options (question_id, text, is_correct, explanation) VALUES
    (q1_id, 'Newton (N)', false, 'Newton is a derived unit (kg·m/s²).'),
    (q1_id, 'Kilogram (kg)', true, 'Kilogram is the SI base unit of mass.'),
    (q1_id, 'Joule (J)', false, 'Joule is a derived unit of energy (N·m).'),
    (q1_id, 'Watt (W)', false, 'Watt is a derived unit of power (J/s).');

    -- Question 2: Physics Grade 11 Unit 1
    INSERT INTO public.questions (id, unit_id, question_text, question_number, order_index, explanation)
    VALUES (
        q2_id,
        '11_physics_unit_1',
        'If vector A has a magnitude of 10 units at an angle of 30° to the horizontal, what is its horizontal component Ax?',
        2,
        2,
        'Ax = A * cos(30°) = 10 * (√3 / 2) ≈ 8.66 units.'
    );

    INSERT INTO public.question_options (question_id, text, is_correct, explanation) VALUES
    (q2_id, '5.0 units', false, 'This is the vertical component Ay = 10 * sin(30°).'),
    (q2_id, '8.66 units', true, 'Correct: Ax = 10 * cos(30°) = 8.66 units.'),
    (q2_id, '10.0 units', false, 'This is the total magnitude of the vector.'),
    (q2_id, '15.0 units', false, 'Components cannot exceed the total magnitude.');

    -- Question 3: Physics Grade 12 Unit 1
    INSERT INTO public.questions (id, unit_id, question_text, question_number, order_index, explanation)
    VALUES (
        q3_id,
        '12_physics_unit_1',
        'According to the First Law of Thermodynamics, what does ΔU represent in the equation ΔU = Q - W?',
        1,
        1,
        'ΔU represents the change in the internal energy of the system.'
    );

    INSERT INTO public.question_options (question_id, text, is_correct, explanation) VALUES
    (q3_id, 'Total external work done', false, 'External work is represented by W.'),
    (q3_id, 'Heat energy transferred', false, 'Heat energy transferred is represented by Q.'),
    (q3_id, 'Change in internal energy', true, 'ΔU is the internal energy change.'),
    (q3_id, 'Universal gas constant', false, 'The gas constant is denoted by R.');
END $$;
