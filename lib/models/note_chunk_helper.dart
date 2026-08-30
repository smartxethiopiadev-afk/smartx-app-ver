import 'note_model.dart';

class NoteChunk {
  final int index;
  final int totalChunks;
  final String title;
  final String text;
  final int wordCount;
  final int estimatedSeconds;

  const NoteChunk({
    required this.index,
    required this.totalChunks,
    required this.title,
    required this.text,
    required this.wordCount,
    required this.estimatedSeconds,
  });
}

class NoteChunkHelper {
  /// Splits a note's text content into chunks based on word count target (e.g. 120-180 words)
  static List<NoteChunk> splitIntoWordChunks(String fullContent, {int targetWordsPerChunk = 150}) {
    if (fullContent.trim().isEmpty) {
      return [
        const NoteChunk(
          index: 1,
          totalChunks: 1,
          title: 'ክፍል 1 (መግቢያ)',
          text: 'ምንም ማስታወሻ አልተገኘም።',
          wordCount: 3,
          estimatedSeconds: 2,
        )
      ];
    }

    // Split text into paragraphs first to keep sentence and thought coherence
    final paragraphs = fullContent.split(RegExp(r'\n\s*\n'));
    final List<String> chunkTexts = [];
    final StringBuffer currentBuffer = StringBuffer();
    int currentWordCount = 0;

    for (var para in paragraphs) {
      final paraTrimmed = para.trim();
      if (paraTrimmed.isEmpty) continue;

      final wordsInPara = paraTrimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      // If adding this paragraph exceeds target words by more than 30%, start new chunk
      if (currentWordCount > 0 && (currentWordCount + wordsInPara) > targetWordsPerChunk) {
        chunkTexts.add(currentBuffer.toString().trim());
        currentBuffer.clear();
        currentWordCount = 0;
      }

      // If single paragraph itself is much larger than targetWordsPerChunk, split it by sentences
      if (wordsInPara > targetWordsPerChunk * 1.5) {
        final sentences = paraTrimmed.split(RegExp(r'(?<=[.?!])\s+'));
        for (var sentence in sentences) {
          final wordsInSentence = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          if (currentWordCount > 0 && (currentWordCount + wordsInSentence) > targetWordsPerChunk) {
            chunkTexts.add(currentBuffer.toString().trim());
            currentBuffer.clear();
            currentWordCount = 0;
          }
          currentBuffer.writeln(sentence);
          currentWordCount += wordsInSentence;
        }
      } else {
        currentBuffer.writeln(paraTrimmed);
        currentBuffer.writeln();
        currentWordCount += wordsInPara;
      }
    }

    if (currentBuffer.isNotEmpty && currentBuffer.toString().trim().isNotEmpty) {
      chunkTexts.add(currentBuffer.toString().trim());
    }

    if (chunkTexts.isEmpty) {
      chunkTexts.add(fullContent.trim());
    }

    final total = chunkTexts.length;
    return List.generate(total, (i) {
      final text = chunkTexts[i];
      final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final estimatedSec = ((wordCount / 140) * 60).round().clamp(10, 300);
      return NoteChunk(
        index: i + 1,
        totalChunks: total,
        title: 'ክፍል ${i + 1} ከ $total',
        text: text,
        wordCount: wordCount,
        estimatedSeconds: estimatedSec,
      );
    });
  }

  /// Rich realistic sample short notes for Ethiopian Curriculum (Maths, Physics, Chemistry, Biology, History, Geography, Economics)
  static Map<String, ShortNoteModel> getSampleNotesCatalog() {
    return {
      // 1. Mathematics G11 U1
      'math_g11_u1': const ShortNoteModel(
        id: 'math_g11_u1_note',
        grade: 11,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Relations and Functions: High-Yield Matric Exam Summary',
        content: '''
# Smart X Ethiopia: Grade 11 Mathematics • Unit 1 (Relations & Functions)

A relation R from set A to set B is any subset of the Cartesian product A × B. A relation f is called a function if and only if every element in the domain A is paired with exactly one unique element in the range B.

Vertical Line Test: A curve in the Cartesian coordinate plane represents the graph of a function y = f(x) if and only if no vertical line intersects the curve at more than one point.

Types of Functions:
1. Injective (One-to-One): A function f is injective if f(x1) = f(x2) implies x1 = x2. It satisfies the Horizontal Line Test where no horizontal line crosses the graph more than once.
2. Surjective (Onto): A function f: A -> B is surjective if every element in the codomain B is an image of at least one element in domain A (Range = Codomain).
3. Bijective (One-to-One Correspondence): A function is bijective if it is both injective and surjective. Only bijective functions have an inverse function f^(-1)(x).

Domain and Range Determination Rules:
- Rule 1 (Fractions): For f(x) = P(x) / Q(x), domain excludes all values of x where denominator Q(x) = 0.
- Rule 2 (Even Radicals): For f(x) = sqrt(g(x)), domain requires radicand g(x) >= 0.
- Rule 3 (Logarithms): For f(x) = log_b(g(x)), domain requires argument g(x) > 0 and base b > 0, b != 1.

Composition of Functions:
Given f(x) and g(x), the composite function (f o g)(x) is defined as f(g(x)).
The domain of (f o g)(x) is the set of all real numbers x in the domain of g such that g(x) is in the domain of f. Note that function composition is associative but generally not commutative: (f o g)(x) != (g o f)(x).

Inverse Functions Properties:
If f has an inverse f^(-1), then:
- Domain of f^(-1) = Range of f.
- Range of f^(-1) = Domain of f.
- The graph of y = f^(-1)(x) is the exact reflection of y = f(x) along the line y = x.
- (f o f^(-1))(x) = x for all x in Domain of f^(-1).

National Exam Pitfalls:
When finding the inverse of a rational function f(x) = (ax + b) / (cx + d), the inverse is always f^(-1)(x) = (-dx + b) / (cx - a). Always specify x != a/c.
''',
      ),

      // 2. Physics G11 U1
      'phy_g11_u1': const ShortNoteModel(
        id: 'phy_g11_u1_note',
        grade: 11,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Vectors and Kinematics in Two Dimensions',
        content: '''
# Smart X Ethiopia: Grade 11 Physics • Unit 1 (Vectors & Physical Quantities)

Physics is an empirical science dealing with fundamental constituents of the universe and their interactions. Physical quantities are classified into scalar quantities (magnitude only, e.g., mass, time, speed, energy) and vector quantities (magnitude and direction, e.g., displacement, velocity, acceleration, force, momentum).

Vector Operations and Representations:
A vector A in Cartesian coordinates is expressed as A = Ax*i + Ay*j + Az*k.
The magnitude |A| = sqrt(Ax^2 + Ay^2 + Az^2).
The direction angle theta in 2D is given by theta = arctan(Ay / Ax).

Scalar (Dot) Product:
The scalar product of two vectors A and B is defined as:
A . B = |A| * |B| * cos(theta) = Ax*Bx + Ay*By + Az*Bz.
Key Properties of Dot Product:
- If A and B are perpendicular (orthogonal), then theta = 90 deg, cos(90) = 0, so A . B = 0.
- Dot product is commutative: A . B = B . A.
- Work done W = F . s = |F|*|s|*cos(theta).

Vector (Cross) Product:
The vector product A × B results in a vector perpendicular to the plane containing both A and B:
|A × B| = |A| * |B| * sin(theta).
Key Properties of Cross Product:
- The direction is determined by the Right-Hand Rule.
- If A and B are parallel or antiparallel, sin(theta) = 0, so A × B = 0.
- Cross product is anti-commutative: A × B = -(B × A).
- Torque tau = r × F = |r|*|F|*sin(theta).

Relative Velocity Equation:
The velocity of body A relative to body B is:
V_AB = V_A - V_B.
For motion across flowing water (river boat problems), vector addition applies: V_resultant = V_boat + V_river.

Exam Trap Alert:
Work is a scalar quantity even though it is calculated from two vectors (Force and Displacement) because it uses the scalar dot product. Torque is a vector quantity resulting from vector cross product.
''',
      ),

      // 3. Chemistry G11 U1
      'chem_g11_u1': const ShortNoteModel(
        id: 'chem_g11_u1_note',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Fundamental Concepts of Matter and Atomic Structure',
        content: '''
# Smart X Ethiopia: Grade 11 Chemistry • Unit 1 (Atomic Structure & Matter)

Modern chemistry is built upon quantum mechanical atomic theory. The atom consists of a dense, positively charged nucleus containing protons and neutrons, surrounded by electrons residing in quantized energy levels.

Quantum Numbers and Atomic Orbitals:
Electrons in an atom are completely described by four quantum numbers:
1. Principal Quantum Number (n): Indicates the main energy level or shell (n = 1, 2, 3, 4...).
2. Angular Momentum Quantum Number (l): Defines the orbital shape (l = 0 for s-orbital, l = 1 for p-orbital, l = 2 for d-orbital, l = 3 for f-orbital). Values range from 0 to (n - 1).
3. Magnetic Quantum Number (ml): Specifies spatial orientation in magnetic fields. Values range from -l to +l. Total orbitals in a subshell = (2l + 1).
4. Spin Quantum Number (ms): Represents intrinsic electron spin (+1/2 or -1/2).

Fundamental Electronic Configuration Principles:
- Aufbau Principle: Electrons occupy lowest-energy orbitals first (1s < 2s < 2p < 3s < 3p < 4s < 3d).
- Pauli Exclusion Principle: No two electrons in the same atom can have the identical set of all four quantum numbers. Therefore, an orbital holds a maximum of 2 electrons with opposite spins.
- Hund Rule of Maximum Multiplicity: Electrons occupy degenerate orbitals singly with parallel spins before pairing occurs.

Periodic Trends Across Periods and Down Groups:
- Atomic Radius: Decreases across a period (due to increasing effective nuclear charge Z_eff) and increases down a group (due to additional electron shells).
- Ionization Energy: Energy required to remove the outermost electron. Generally increases across a period and decreases down a group. Note anomalies: Nitrogen (group 15) has higher ionization energy than Oxygen (group 16) due to stable half-filled 2p^3 configuration.
- Electronegativity: Fluorine is the most electronegative element (4.0 on Pauling scale). Increases across period and decreases down group.

Stoichiometry and Mole Concept:
- Number of moles n = Mass (m) / Molar Mass (M).
- 1 mole = 6.022 × 10^23 particles (Avogadro Constant).
- At standard temperature and pressure (STP: 0 deg C, 1 atm), 1 mole of any ideal gas occupies 22.4 Liters.
''',
      ),

      // 4. Biology G11 U1
      'bio_g11_u1': const ShortNoteModel(
        id: 'bio_g11_u1_note',
        grade: 11,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Cell Biology, Enzymes, and Biochemical Principles',
        content: '''
# Smart X Ethiopia: Grade 11 Biology • Unit 1 (The Science of Biology & Cytology)

Biology is the scientific study of living organisms and vital life processes. Life is characterized by cellular organization, metabolism, homeostasis, growth, reproduction, response to stimuli, and evolutionary adaptation.

Cell Theory Fundamentals:
1. All living organisms are composed of one or more cells.
2. The cell is the basic structural and functional unit of all life.
3. All cells arise only from pre-existing cells through cell division (Omnis cellula e cellula).

Prokaryotic vs. Eukaryotic Cells:
- Prokaryotes (Bacteria & Archaea): Lack membrane-bound nucleus and organelles; circular DNA in nucleoid region; 70S ribosomes; divide by binary fission.
- Eukaryotes (Plants, Animals, Fungi, Protists): Membrane-bound nucleus containing linear chromosomes; membrane-bound organelles (Mitochondria, ER, Golgi); 80S ribosomes; divide by mitosis/meiosis.

Eukaryotic Organelles and Their Primary Functions:
- Mitochondria: Double-membraned powerhouse; site of Krebs Cycle (matrix) and Oxidative Phosphorylation (cristae) generating ATP.
- Chloroplasts: Site of photosynthesis; thylakoids contain chlorophyll for light reactions, stroma for Calvin cycle.
- Ribosomes: Non-membranous complexes of rRNA and proteins responsible for protein translation.
- Endoplasmic Reticulum (ER): Rough ER (studded with ribosomes) synthesizes secretory proteins; Smooth ER synthesizes lipids and detoxifies chemicals.
- Golgi Apparatus: Modifies, sorts, packages, and tags proteins for secretion or cellular routing.
- Lysosomes: Contain hydrolytic acid enzymes for intracellular digestion and autolysis.

Enzymes and Biocatalysis:
Enzymes are biological catalysts (primarily globular proteins) that accelerate chemical reactions by lowering the activation energy (Ea) without being consumed in the reaction.
- Active site binds substrate via Induced Fit Model.
- Factors affecting enzyme activity: Temperature (denaturation at extreme heat), pH (optimum pH varies by enzyme, e.g., pepsin pH 2 vs. trypsin pH 8), and substrate concentration.
- Enzyme Inhibition: Competitive inhibitors bind directly to the active site (reversible by increasing substrate concentration); Non-competitive inhibitors bind to allosteric sites altering the catalytic shape.
''',
      ),

      // 5. History G11 U1
      'hist_g11_u1': const ShortNoteModel(
        id: 'hist_g11_u1_note',
        grade: 11,
        subject: 'History',
        unitNumber: 1,
        title: 'Historiography, Human Evolution, and Ancient Civilizations',
        content: '''
# Smart X Ethiopia: Grade 11 History • Unit 1 (Historiography & Human Origins)

History is the systematic and critical study of past human events based on verifiable evidence. Historiography refers to the history of historical writing, methodology, and interpretation.

Historical Sources and Evidence:
1. Primary Sources: Direct, first-hand evidence contemporary with the event. Examples: archaeological artifacts, inscriptions (e.g., Yeha, Axumite stelae), coins, treaties, diaries, and original eyewitness accounts.
2. Secondary Sources: Works written after the event by researchers who interpret primary sources. Examples: textbooks, biographies, historical review articles.
3. Oral Traditions: Spoken accounts, legends, and folk poems passed down through generations; essential in African historiography.

Human Origins and Ethiopia as the Cradle of Humankind:
The East African Rift Valley, particularly Ethiopia's Afar Triangle (Awash Valley) and Omo Basin, has yielded the world's most significant hominid fossil discoveries:
- Ardipithecus ramidus (Ardi): Discovered at Aramis, Middle Awash in 1994, dated to ~4.4 million years ago.
- Australopithecus afarensis (Dinkenesh / Lucy): Discovered at Hadar in 1974 by Donald Johanson, dated to ~3.2 million years ago; provides definitive evidence of habitual bipedalism.
- Homo sapiens idaltu: Discovered at Herto (Afar), dated to ~160,000 years ago, representing early anatomically modern humans.

Stone Age Technological Transitions:
- Paleolithic (Old Stone Age): Hunting and gathering; development of Oldowan pebble tools followed by Acheulean handaxes.
- Mesolithic (Middle Stone Age): Specialized microlithic blade tools and composite implements.
- Neolithic (New Stone Age): The Neolithic Agricultural Revolution; transition from nomadic food foraging to sedentary agriculture, animal domestication, pottery, and permanent village settlements.
''',
      ),

      // 6. Geography G11 U1
      'geo_g11_u1': const ShortNoteModel(
        id: 'geo_g11_u1_note',
        grade: 11,
        subject: 'Geography',
        unitNumber: 1,
        title: 'Geological Structure, Plate Tectonics, and Ethiopian Relief',
        content: '''
# Smart X Ethiopia: Grade 11 Geography • Unit 1 (Geology & Landforms of Ethiopia)

Geography studies the spatial distribution of physical environments and human societies across Earth. Physical geography focuses on lithosphere, atmosphere, hydrosphere, and biosphere interactions.

Geological Eras and Ethiopian Formations:
1. Precambrian Era (Oldest, over 600 million years ago):
   - Formation of the Basement Complex (crystalline rocks: granites, gneisses, schists).
   - Exposed today in northern Tigray, western Gojjam/Wollega, and southern Sidama/Borena.
2. Paleozoic Era:
   - Prolonged denudation and peneplanation; no major rock deposition in the Horn.
3. Mesozoic Era:
   - Transgression and regression of the Indian Ocean, depositing sedimentary strata: Adigrat Sandstone (bottom), Antalo Limestone (middle), and Upper Sandstone (top).
4. Cenozoic Era:
   - Tertiary Period: Intense volcanic outpourings forming the Trap Series (highland basalt plateaus) and Rift Valley fracturing.
   - Quaternary Period: Pluvial climates forming Rift Valley lakes and recent volcanic cones (Erta Ale, Fantale).

Physiographic Regions of Ethiopia:
- Western Highlands and Lowlands: Includes Simien Mountains (Ras Dejen, 4533m), Shewan plateau, and western river basins (Abay, Baro, Tekeze).
- Southeastern Highlands and Lowlands: Includes Bale Mountains (Mount Batu), Arsi-Bale massifs, and Ogaden plain.
- Ethiopian Rift Valley: Divides the country into two highland systems; features Afar depression (Danakil at -125m below sea level) and the Lakes region (Ziway, Langano, Hawassa, Chamo, Abaya).
''',
      ),

      // 7. Economics G11 U1
      'econ_g11_u1': const ShortNoteModel(
        id: 'econ_g11_u1_note',
        grade: 11,
        subject: 'Economics',
        unitNumber: 1,
        title: 'Microeconomics: Scarcity, Opportunity Cost, and Market Forces',
        content: '''
# Smart X Ethiopia: Grade 11 Economics • Unit 1 (Foundations of Economics)

Economics is the social science that studies how individuals, governments, and societies allocate scarce productive resources to satisfy unlimited human wants.

Fundamental Economic Problems:
The central problem of economics is Scarcity. Because resources (Land, Labor, Capital, Entrepreneurship) are finite while human wants are insatiable, society must answer three fundamental questions:
1. What to produce and in what quantities?
2. How to produce (labor-intensive vs. capital-intensive techniques)?
3. For whom to produce (distribution of national output)?

Opportunity Cost and Production Possibility Frontier (PPF):
- Opportunity Cost: The value of the next best alternative forgone when a choice is made.
- PPF Curve: A graphical representation of the maximum output combinations of two goods an economy can produce given fixed technology and full employment of resources.
- Points on the PPF curve are productive efficient.
- Points inside the PPF represent unemployment or inefficient resource utilization.
- Points outside the PPF are unattainable with current resources.
- The downward slope and concave shape of the PPF illustrate the Law of Increasing Opportunity Cost.

Market Demand, Supply, and Equilibrium:
- Law of Demand: Other factors held constant (ceteris paribus), as price increases, quantity demanded decreases (inverse relationship).
- Law of Supply: Other factors held constant, as price increases, quantity supplied increases (direct relationship).
- Market Equilibrium: Occurs at price Pe where Quantity Demanded = Quantity Supplied.
- If Price > Pe: Surplus (Excess Supply) emerges, exerting downward price pressure.
- If Price < Pe: Shortage (Excess Demand) emerges, exerting upward price pressure.

Elasticity of Demand:
Price Elasticity of Demand (Ped) = (% Change in Quantity Demanded) / (% Change in Price).
- Elastic (|Ped| > 1): Quantity responds strongly to price changes.
- Inelastic (|Ped| < 1): Quantity responds weakly (necessities, staple foods).
- Unit Elastic (|Ped| = 1): Total revenue remains unchanged with price variation.
''',
      ),
    };
  }
}
