-- ==============================================================================
-- Smart X ET - Supabase Database Schema Migration
-- Short Notes (HTML/CSS) and Questions Sequential Ordering
-- ==============================================================================

-- 1. Create short_notes Table for Rich HTML/CSS Study Notes
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

-- Index for instant querying by Grade, Subject, and Unit Number
CREATE INDEX IF NOT EXISTS idx_short_notes_grade_subject_unit 
ON public.short_notes (grade, subject, unit_number);

-- Enable Row Level Security (RLS) and grant read access to all users
ALTER TABLE public.short_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on short_notes" 
ON public.short_notes 
FOR SELECT 
USING (true);

CREATE POLICY "Allow authenticated insert/update on short_notes"
ON public.short_notes
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 2. Update Questions Table for Sequential Ordering
ALTER TABLE public.questions 
ADD COLUMN IF NOT EXISTS question_number INTEGER,
ADD COLUMN IF NOT EXISTS order_index INTEGER;

CREATE INDEX IF NOT EXISTS idx_questions_unit_seq 
ON public.questions (unit_id, question_number, order_index);

-- 3. Sample Seed Data for Short Notes (HTML/CSS Formatted)
INSERT INTO public.short_notes (grade, subject, unit_number, title, html_content)
VALUES 
(
    11,
    'physics',
    1,
    'Measurement and Practical Work',
    '<h2>Unit 1: Measurement and Practical Work</h2>
    <div class="callout">
      <strong>Core Focus:</strong> Fundamental units, dimensional analysis, uncertainty calculation, and scientific reporting.
    </div>
    <h3>1. Physical Quantities & SI Units</h3>
    <p>Physical quantities are classified into <strong>base quantities</strong> (Length, Mass, Time, Electric Current, Temperature, Amount of substance, Luminous intensity) and <strong>derived quantities</strong> (Force, Energy, Power, Pressure, Velocity).</p>
    <table>
      <thead>
        <tr><th>Quantity</th><th>Base Unit</th><th>Symbol</th><th>Dimension</th></tr>
      </thead>
      <tbody>
        <tr><td>Length</td><td>Meter</td><td>m</td><td>[L]</td></tr>
        <tr><td>Mass</td><td>Kilogram</td><td>kg</td><td>[M]</td></tr>
        <tr><td>Time</td><td>Second</td><td>s</td><td>[T]</td></tr>
        <tr><td>Current</td><td>Ampere</td><td>A</td><td>[I]</td></tr>
      </tbody>
    </table>
    <h3>2. Vectors & Scalar Quantities</h3>
    <p>Scalars possess magnitude only (e.g., speed, distance, mass, energy), whereas vectors have both magnitude and direction (e.g., displacement, velocity, acceleration, force).</p>
    <div class="formula">
      <strong>Vector Resolution:</strong><br>
      A<sub>x</sub> = A &times; cos(&theta;)<br>
      A<sub>y</sub> = A &times; sin(&theta;)<br>
      |A| = &radic;(A<sub>x</sub><sup>2</sup> + A<sub>y</sub><sup>2</sup>)
    </div>
    <h3>3. Errors and Uncertainties</h3>
    <ul>
      <li><strong>Systematic Errors:</strong> Consistent errors caused by flawed instruments or procedures (e.g., zero error).</li>
      <li><strong>Random Errors:</strong> Unpredictable fluctuations minimized by repeated trials.</li>
    </ul>'
),
(
    12,
    'physics',
    1,
    'Thermodynamics and Heat Engines',
    '<h2>Unit 1: Thermodynamics</h2>
    <div class="callout">
      <strong>Core Focus:</strong> Laws of thermodynamics, Carnot cycle, heat engines, and entropy.
    </div>
    <h3>1. The Zeroth & First Laws of Thermodynamics</h3>
    <p>The First Law is the conservation of energy applied to thermal systems:</p>
    <div class="formula">
      &Delta;U = Q - W
    </div>
    <p>Where <em>&Delta;U</em> is change in internal energy, <em>Q</em> is heat added to system, and <em>W</em> is work done by the system.</p>
    <h3>2. Heat Engines & Carnot Efficiency</h3>
    <p>No engine can be more efficient than a reversible Carnot engine operating between two temperatures <em>T<sub>H</sub></em> and <em>T<sub>C</sub></em> (in Kelvin).</p>
    <div class="formula">
      &eta;<sub>Carnot</sub> = 1 - (T<sub>C</sub> / T<sub>H</sub>)
    </div>'
),
(
    11,
    'mathematics',
    1,
    'Further on Relations and Functions',
    '<h2>Unit 1: Relations and Functions</h2>
    <div class="callout">
      <strong>Key Concept:</strong> One-to-one, onto functions, inverse functions, and composition of functions.
    </div>
    <h3>1. Composition of Functions</h3>
    <p>Given functions <em>f: A &rarr; B</em> and <em>g: B &rarr; C</em>, the composite function <em>(g &comp; f)(x) = g(f(x))</em>.</p>
    <h3>2. Inverse of a Function</h3>
    <p>A function <em>f(x)</em> has an inverse <em>f<sup>-1</sup>(x)</em> if and only if <em>f</em> is <strong>bijective</strong> (both one-to-one and onto).</p>'
),
(
    12,
    'chemistry',
    1,
    'Solutions and Colloids',
    '<h2>Unit 1: Solutions</h2>
    <div class="callout">
      <strong>Key Concept:</strong> Types of solutions, solubility, Henry''s law, and colligative properties.
    </div>
    <h3>1. Concentration Units</h3>
    <ul>
      <li><strong>Molarity (M):</strong> moles of solute / liters of solution</li>
      <li><strong>Molality (m):</strong> moles of solute / kg of solvent</li>
      <li><strong>Mole Fraction (X):</strong> moles of component / total moles</li>
    </ul>
    <div class="formula">
      <strong>Raoult''s Law:</strong> P<sub>solution</sub> = X<sub>solvent</sub> &times; P&deg;<sub>solvent</sub>
    </div>'
)
ON CONFLICT DO NOTHING;
