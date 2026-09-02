class CurriculumUnits {
  static List<Map<String, dynamic>> getUnits({
    required String subjectId,
    required int grade,
  }) {
    switch (subjectId) {
      // ==========================================
      // MATHEMATICS
      // ==========================================
      case 'Mathematics':
        if (grade == 9) {
          return [
            {
              'id': 'math_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Further on Sets',
              'amUnit': 'ክፍል 1: ተጨማሪ በስብስቦች ላይ',
              'enDesc': 'Set operations, Venn diagrams, Cartesian products, and applications.',
              'amDesc': 'የስብስብ ስሌቶች፣ ቬን ዳያግራም፣ የካርቴዥያን ብዜት እና አተገባበሩ።',
            },
            {
              'id': 'math_u2',
              'grade': 9,
              'enUnit': 'Unit 2: The Number System',
              'amUnit': 'ክፍል 2: የቁጥር ስርዓት',
              'enDesc': 'Rational and irrational numbers, real numbers, roots, and exponents.',
              'amDesc': 'አሳማኝና ኢ-አሳማኝ ቁጥሮች፣ ሪል ቁጥሮች፣ ራዲካል እና ኤክስፖነንት።',
            },
            {
              'id': 'math_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Solving Equations',
              'amUnit': 'ክፍል 3: እኩልታዎችን መፍታት',
              'enDesc': 'Linear and quadratic equations, system of linear equations in two variables.',
              'amDesc': 'መስመራዊ እና ኳድራቲክ እኩልታዎች፣ እና ባለ ሁለት ተለዋዋጭ መስመራዊ እኩልታዎች።',
            },
            {
              'id': 'math_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Solving Inequalities',
              'amUnit': 'ክፍል 4: አለመመጣጠኖችን መፍታት',
              'enDesc': 'Linear inequalities in one and two variables, systems of linear inequalities.',
              'amDesc': 'ባለ አንድ እና ባለ ሁለት ተለዋዋጭ መስመራዊ አለመመጣጠኖች መፍትሄ።',
            },
            {
              'id': 'math_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Introduction to Trigonometry',
              'amUnit': 'ክፍል 5: የትሪጎኖሜትሪ መግቢያ',
              'enDesc': 'Trigonometric ratios (sine, cosine, tangent), special angles, and right triangles.',
              'amDesc': 'ትሪጎኖሜትሪክ ሬሾዎች (ሳይን፣ ኮሳይን፣ ታንጀንት) እና የቀኝ ማዕዘን ትሪያንግሎች።',
            },
            {
              'id': 'math_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Regular Polygons',
              'amUnit': 'ክፍል 6: መደበኛ ፖሊጎኖች',
              'enDesc': 'Interior and exterior angles, properties, perimeters, and areas of regular polygons.',
              'amDesc': 'የውስጥ እና የውጭ ማዕዘኖች፣ የመደበኛ ፖሊጎኖች ባህሪያት እና ስፋት።',
            },
            {
              'id': 'math_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Congruency and Similarity',
              'amUnit': 'ክፍል 7: አንድነት እና ተመሳሳይነት',
              'enDesc': 'Congruent and similar triangles, conditions of congruency and similarity, theorems.',
              'amDesc': 'ተመሳሳይ እና አንድ የሆኑ ትሪያንግሎች፣ የአንድነት እና የተመሳሳይነት ህጎች።',
            },
            {
              'id': 'math_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Vectors in Two Dimensions',
              'amUnit': 'ክፍል 8: ባለ ሁለት አቅጣጫ ቬክተሮች',
              'enDesc': 'Vector representation, addition, subtraction, scalar multiplication, and magnitude.',
              'amDesc': 'የቬክተር ውክልና፣ ድምር፣ ቅነሳ፣ በስካላር ማባዛት እና የቬክተር ርዝመት።',
            },
            {
              'id': 'math_u9',
              'grade': 9,
              'enUnit': 'Unit 9: Statistics and Probability',
              'amUnit': 'ክፍል 9: ስታቲስቲክስ እና ፕሮባብሊቲ',
              'enDesc': 'Data organization, frequency distribution, central tendency measures, and basic probability.',
              'amDesc': 'የመረጃ አደረጃጀት፣ የፍሪኩዌንሲ ስርጭት፣ አማካይ (Mean, Median, Mode) እና ፕሮባብሊቲ።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'math_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Relations and Functions',
              'amUnit': 'ክፍል 1: ግንኙነቶች እና ተግባራት',
              'enDesc': 'Relations, domain and range, inverse relations, function notation, and graphs.',
              'amDesc': 'ግንኙነቶች፣ ዶሜይን እና ሬንጅ፣ የተገላቢጦሽ ግንኙነቶች እና የተግባራት ግራፎች።',
            },
            {
              'id': 'math_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Polynomial Functions',
              'amUnit': 'ክፍል 2: ፖሊኖሚያል ተግባራት',
              'enDesc': 'Operations on polynomials, remainder theorem, factor theorem, roots, and graphing.',
              'amDesc': 'በፖሊኖሚያል ላይ የሚሰሩ ስሌቶች፣ ቀሪ እና ፋክተር ቲዎረሞች እና ስረ-ቁጥሮች።',
            },
            {
              'id': 'math_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Exponential and Logarithmic Functions',
              'amUnit': 'ክፍል 3: ኤክስፖኔንሻል እና ሎጋሪዝም ተግባራት',
              'enDesc': 'Laws of exponents and logarithms, graphs of exponential and logarithmic functions.',
              'amDesc': 'የኤክስፖነንት እና ሎጋሪዝም ህጎች፣ እና የተግባራቱ ግራፎችና እኩልታዎች።',
            },
            {
              'id': 'math_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Trigonometric Functions',
              'amUnit': 'ክፍል 4: ትሪጎኖሜትሪክ ተግባራት',
              'enDesc': 'Radian measures, unit circle, trigonometric graphs, identities, and equations.',
              'amDesc': 'የራዲያን መለኪያ፣ ዩኒት ሰርክል፣ የትሪጎኖሜትሪክ ተግባራት ግራፎች እና ቀመሮች።',
            },
            {
              'id': 'math_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Circles',
              'amUnit': 'ክፍል 5: ክበቦች',
              'enDesc': 'Properties of chords, tangents, secants, angles subtended by arcs, and cyclic quadrilaterals.',
              'amDesc': 'የኮርዶች፣ ታንጀንቶች፣ ሰካንቶች እና በክበብ ዙሪያ ያሉ ማዕዘናት ባህሪያት።',
            },
            {
              'id': 'math_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Solid Figures',
              'amUnit': 'ክፍል 6: ሶሊድ ቅርጾች',
              'enDesc': 'Surface areas and volumes of prisms, pyramids, cylinders, cones, and spheres.',
              'amDesc': 'የፕሪዝም፣ ፒራሚድ፣ ሲሊንደር፣ ኮን እና ሉል (Sphere) የገጽታ ስፋት እና ይዘት።',
            },
            {
              'id': 'math_u7',
              'grade': 10,
              'enUnit': 'Unit 7: Coordinate Geometry',
              'amUnit': 'ክፍል 7: መጋጠሚያ ጂኦሜትሪ',
              'enDesc': 'Distance formula, midpoint, equations of straight lines, parallel and perpendicular slopes.',
              'amDesc': 'የነጥቦች ርቀት ቀመር፣ መካከለኛ ነጥብ፣ የመስመሮች እኩልታ እና ትይዩ/ቀጥተኛ መስመሮች።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'math_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Relations and Functions',
              'amUnit': 'ክፍል 1: ግንኙነቶች እና ተግባራት',
              'enDesc': 'Composition of functions, inverse functions, rational functions, and transformations.',
              'amDesc': 'የተግባራት ውህደት፣ የተገላቢጦሽ ተግባራት እና ራሽናል ተግባራት።',
            },
            {
              'id': 'math_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Matrices and Determinants',
              'amUnit': 'ክፍል 2: ማትሪክስ እና ዲተርሚናንቶች',
              'enDesc': 'Matrix algebra, determinants, inverse matrices, and systems of linear equations (Cramer\'s rule).',
              'amDesc': 'የማትሪክስ ስሌቶች፣ ዲተርሚናንቶች፣ ኢንቨርስ ማትሪክስ እና የመስመራዊ እኩልታዎች መፍትሄ።',
            },
            {
              'id': 'math_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Vectors',
              'amUnit': 'ክፍል 3: ቬክተሮች',
              'enDesc': 'Vectors in 2D and 3D, dot product, angle between vectors, direction cosines, and projections.',
              'amDesc': 'በ2D እና 3D ውስጥ ቬክተሮች፣ ዶት ብዜት፣ በቬክተሮች መካከል ያለ ማዕዘን እና ፕሮጀክሽን።',
            },
            {
              'id': 'math_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Transformations',
              'amUnit': 'ክፍል 4: ትራንስፎርሜሽን',
              'enDesc': 'Translations, rotations, reflections, dilations, and combined geometric transformations.',
              'amDesc': 'ትራንስሌሽን፣ ሽክርክሪት (Rotation)፣ ነጸብራቅ (Reflection) እና ዳይሌሽን።',
            },
            {
              'id': 'math_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Statistics',
              'amUnit': 'ክፍል 5: ስታቲስቲክስ',
              'enDesc': 'Measures of dispersion: range, variance, standard deviation, and coefficient of variation.',
              'amDesc': 'የመበታተን መለኪያዎች፡ ሬንጅ፣ ቫሪያንስ፣ ስታንዳርድ ዴቪዬሽን እና ንጽጽር።',
            },
            {
              'id': 'math_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Probability',
              'amUnit': 'ክፍል 6: ፕሮባብሊቲ',
              'enDesc': 'Counting principles, permutations, combinations, conditional probability, and independent events.',
              'amDesc': 'የመቁጠር መርሆዎች፣ ፐርሙቴሽን፣ ኮምቢኔሽን እና ቅድመ-ሁኔታ ፕሮባብሊቲ።',
            },
            {
              'id': 'math_u7',
              'grade': 11,
              'enUnit': 'Unit 7: Introduction to Calculus',
              'amUnit': 'ክፍል 7: የካልኩለስ መግቢያ',
              'enDesc': 'Intuitive concept of limits, rate of change, tangents to curves, and basic derivative concept.',
              'amDesc': 'የሊሚት ጽንሰ-ሀሳብ፣ የለውጥ ፍጥነት እና የተዋጽኦ (Derivative) መግቢያ።',
            },
            {
              'id': 'math_u8',
              'grade': 11,
              'enUnit': 'Unit 8: Applications of Mathematics',
              'amUnit': 'ክፍል 8: የሂሳብ አተገባበር',
              'enDesc': 'Mathematics in finance (simple and compound interest, depreciation), and linear programming.',
              'amDesc': 'የፋይናንስ ሂሳብ (ወለድ፣ የዋጋ መቀነስ) እና መስመራዊ ፕሮግራሚንግ (Linear Programming)።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'math_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Limits and Continuity',
              'amUnit': 'ክፍል 1: ሊሚት እና ተከታታይነት',
              'enDesc': 'Properties of limits, one-sided limits, infinite limits, and continuity of functions.',
              'amDesc': 'የሊሚት ባህሪያት፣ የአንድ ወገን ሊሚቶች፣ ማለቂያ የሌላቸው ሊሚቶች እና የተግባራት ቀጣይነት።',
            },
            {
              'id': 'math_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Differentiation',
              'amUnit': 'ክፍል 2: ዲፈረንሼሽን',
              'enDesc': 'Derivatives, differentiation rules, chain rule, implicit differentiation, and rate of change.',
              'amDesc': 'ተዋጽኦዎች፣ የዲፈረንሼሽን ደንቦች፣ የቼይን ህግ፣ ግልጽ ያልሆነ ዲፈረንሼሽን እና የለውጥ ፍጥነት።',
            },
            {
              'id': 'math_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Integration',
              'amUnit': 'ክፍል 3: ኢንቴግሬሽን',
              'enDesc': 'Antiderivatives, indefinite and definite integrals, substitution, and area under curves.',
              'amDesc': 'ፀረ-ተዋጽኦዎች፣ የተወሰኑ እና ያልተወሰኑ ኢንቴግራሎች፣ የቅያሬ ዘዴ እና የቦታ ስፋት።',
            },
            {
              'id': 'math_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Vectors and Three-Dimensional Geometry',
              'amUnit': 'ክፍል 4: ቬክተሮች እና ባለ 3-ዲ ጂኦሜትሪ',
              'enDesc': '3D coordinates, vectors in space, dot product, cross product, lines, and planes in 3D.',
              'amDesc': 'የ3D መጋጠሚያዎች፣ ቬክተሮች በጠፈር፣ ዶት እና ክሮስ ብዜቶች፣ መስመሮች እና ጠፍጣፋ ገጾች በጠፈር።',
            },
            {
              'id': 'math_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Statistics and Probability',
              'amUnit': 'ክፍል 5: ስታቲስቲክስ እና ፕሮባብሊቲ',
              'enDesc': 'Probability distributions, expected value, binomial distributions, and normal distribution.',
              'amDesc': 'የፕሮባብሊቲ ስርጭት፣ የሚጠበቅ እሴት፣ ባይኖሚያል እና ኖርማል ስርጭቶች።',
            },
          ];
        }
        return [];

      // ==========================================
      // BIOLOGY
      // ==========================================
      case 'Biology':
        if (grade == 9) {
          return [
            {
              'id': 'bio_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Introduction to Biology',
              'amUnit': 'ክፍል 1: ስለ ስነ-ህይወት መግቢያ',
              'enDesc': 'The study of life, scientific methods, biological equipment, and microscopy.',
              'amDesc': 'የስነ-ህይወት ሳይንስ ምንነት፣ ሳይንሳዊ ዘዴዎች፣ መሳሪያዎች እና ማይክሮስኮፕ።',
            },
            {
              'id': 'bio_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Characteristics and Classification of Organisms',
              'amUnit': 'ክፍል 2: የህያዋን ፍጥረታት ባህሪያት እና ምደባ',
              'enDesc': 'Principles of classification, taxonomy, kingdoms, and domains of life.',
              'amDesc': 'የፍጥረታት ምደባ መርሆዎች፣ ታክሶኖሚ እና የህይወት ዋና ዋና ክፍሎች።',
            },
            {
              'id': 'bio_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Cells',
              'amUnit': 'ክፍል 3: ሴሎች',
              'enDesc': 'Cell theory, cell structure, organelles, prokaryotic and eukaryotic cells.',
              'amDesc': 'የሴል ቲዎሪ፣ የሴል አወቃቀር፣ ኦርጋኔሎች፣ ፕሮካሪዮቲክ እና ዩካሪዮቲክ ሴሎች።',
            },
            {
              'id': 'bio_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Reproduction',
              'amUnit': 'ክፍል 4: ስነ-ተዋልዶ',
              'enDesc': 'Asexual and sexual reproduction mechanisms in plants and animals.',
              'amDesc': 'ኢ-ጾታዊ እና ጾታዊ የስነ-ተዋልዶ መንገዶች በዕፅዋት እና በእንስሳት።',
            },
            {
              'id': 'bio_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Human Health, Nutrition, and Disease',
              'amUnit': 'ክፍል 5: የሰው ጤና፣ አመጋገብ እና በሽታዎች',
              'enDesc': 'Balanced diets, nutrient deficiency, communicable and non-communicable diseases.',
              'amDesc': 'የተመጣጠነ ምግብ፣ የአመጋገብ ጉድለት፣ ተላላፊ እና ተላላፊ ያልሆኑ በሽታዎች።',
            },
            {
              'id': 'bio_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Ecology',
              'amUnit': 'ክፍል 6: ስነ-ምህዳር',
              'enDesc': 'Ecosystem components, biotic and abiotic factors, food chains, webs, and nutrient cycles.',
              'amDesc': 'የስነ-ምህዳር ክፍሎች፣ የምግብ ሰንሰለት እና አልሚ ንጥረ ነገሮች ዑደት።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'bio_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Sub-fields of Biology',
              'amUnit': 'ክፍል 1: የባዮሎጂ ንዑሳን ዘርፎች',
              'enDesc': 'Branches of biology, biotechnology, molecular biology, and applied sciences.',
              'amDesc': 'የባዮሎጂ ቅርንጫፎች፣ ባዮቴክኖሎጂ፣ ሞለኪውላር ባዮሎጂ እና ተግባራዊ ሳይንሶች።',
            },
            {
              'id': 'bio_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Plants',
              'amUnit': 'ክፍል 2: ዕፅዋት',
              'enDesc': 'Plant morphology, anatomy, photosynthesis, transpiration, and economic importance.',
              'amDesc': 'የዕፅዋት አወቃቀር፣ ፎቶሲንተሲስ፣ ትራንስፓይሬሽን እና ኢኮኖሚያዊ ጠቀሜታ።',
            },
            {
              'id': 'bio_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Biochemical Molecules',
              'amUnit': 'ክፍል 3: ባዮኬሚካላዊ ሞለኪውሎች',
              'enDesc': 'Carbohydrates, lipids, proteins, nucleic acids, vitamins, and minerals.',
              'amDesc': 'ካርቦሃይድሬት፣ ሊፒድ፣ ፕሮቲን፣ ኑክሊክ አሲድ፣ ቪታሚኖች እና ማዕድናት።',
            },
            {
              'id': 'bio_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Cell Reproduction',
              'amUnit': 'ክፍል 4: የህዋስ ክፍፍል',
              'enDesc': 'Cell cycle, mitosis, meiosis, gametogenesis, and chromosomal inheritance.',
              'amDesc': 'የሴል ዑደት፣ ማይቶሲስ፣ ሚዮሲስ እና የክሮሞሶም ባህሪያት።',
            },
            {
              'id': 'bio_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Human Biology',
              'amUnit': 'ክፍል 5: የሰው ባዮሎጂ',
              'enDesc': 'Human organ systems: nervous system, endocrine glands, sense organs, and homeostasis.',
              'amDesc': 'የሰው አካል ስርዓቶች፡ የነርቭ ስርዓት፣ የሆርሞን እጢዎች፣ የስሜት ህዋሳት እና ሆሚዮስታሲስ።',
            },
            {
              'id': 'bio_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Ecological Interaction',
              'amUnit': 'ክፍል 6: ስነ-ምህዳራዊ መስተጋብር',
              'enDesc': 'Symbiosis, predation, competition, energy flow, and biodiversity conservation.',
              'amDesc': 'ሲምባዮሲስ፣ ፕሪዴሽን፣ ውድድር፣ የሃይል ፍሰት እና የብዝሃ ህይወት ጥበቃ።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'bio_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Biology and Technology',
              'amUnit': 'ክፍል 1: ባዮሎጂ እና ቴክኖሎጂ',
              'enDesc': 'Application of biological principles in technology, medicine, and agriculture.',
              'amDesc': 'የባዮሎጂ መርሆዎች በቴክኖሎጂ፣ በህክምና እና በግብርና ውስጥ ያላቸው አተገባበር።',
            },
            {
              'id': 'bio_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Characteristics of Animals',
              'amUnit': 'ክፍል 2: የእንስሳት ባህሪያት',
              'enDesc': 'Animal kingdom classification, invertebrates, vertebrates, and comparative anatomy.',
              'amDesc': 'የእንስሳት ምደባ፣ አከርካሪ አጥንት ያላቸው እና የሌላቸው እንስሳት አወቃቀር።',
            },
            {
              'id': 'bio_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Enzymes',
              'amUnit': 'ክፍል 3: ኢንዛይሞች',
              'enDesc': 'Enzyme structure, mechanism of action, enzyme kinetics, and factors affecting rates.',
              'amDesc': 'የኢንዛይም አወቃቀር፣ የአሰራር ዘዴ፣ የኢንዛይም ኪነቲክስ እና ተፅዕኖ ፈጣሪ ሁኔታዎች።',
            },
            {
              'id': 'bio_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Genetics',
              'amUnit': 'ክፍል 4: ጄኔቲክስ',
              'enDesc': 'Mendelian genetics, monohybrid and dihybrid crosses, sex determination, and mutations.',
              'amDesc': 'የሜንደል ጄኔቲክስ ህጎች፣ የጾታ ውሳኔ፣ የጂን ሚውቴሽን እና የዘረመል ውርስ።',
            },
            {
              'id': 'bio_u5',
              'grade': 11,
              'enUnit': 'Unit 5: The Human Body Systems',
              'amUnit': 'ክፍል 5: የሰው አካል ስርዓቶች',
              'enDesc': 'Digestive, circulatory, respiratory, excretory, and immune systems physiology.',
              'amDesc': 'የምግብ መፈጨት፣ የደም ዝውውር፣ የመተንፈሻ፣ የቆሻሻ ማስወገጃ እና የበሽታ መከላከያ ስርዓቶች።',
            },
            {
              'id': 'bio_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Population and Natural Resources',
              'amUnit': 'ክፍል 6: የህዝብ ብዛት እና የተፈጥሮ ሀብት',
              'enDesc': 'Population ecology, human demographic trends, renewable and non-renewable resources.',
              'amDesc': 'የህዝብ ብዛት ስነ-ምህዳር፣ የሰው ልጅ የስነ-ህዝብ አዝማሚያ እና የተፈጥሮ ሀብት ጥበቃ።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'bio_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Application of Biology',
              'amUnit': 'ክፍል 1: የባዮሎጂ አተገባበር',
              'enDesc': 'Recombinant DNA technology, genetic engineering, cloning, GMOs, and bioethics.',
              'amDesc': 'ዳግም የተዋሃደ የዲኤንኤ ቴክኖሎጂ፣ የዘረመል ምህንድስና፣ ክሎኒንግ፣ ጂኤምኦ እና ባዮኤቲክስ።',
            },
            {
              'id': 'bio_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Microorganisms',
              'amUnit': 'ክፍል 2: ረቂቅ ተሕዋስያን',
              'enDesc': 'Bacteria, viruses, fungi, protozoa, microbial genetics, and pathogen management.',
              'amDesc': 'ባክቴሪያ፣ ቫይረሶች፣ ፈንገሶች፣ ፕሮቶዞአ እና ረቂቅ ተሕዋስያንን መቆጣጠር።',
            },
            {
              'id': 'bio_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Energy transformation',
              'amUnit': 'ክፍል 3: የሃይል ልውውጥ',
              'enDesc': 'Cellular respiration, glycolysis, citric acid cycle, electron transport chain, and ATP synthesis.',
              'amDesc': 'የህዋስ መተንፈስ፣ ግላይኮላይሲስ፣ የክሬብስ ዑደት እና የኤቲፒ (ATP) ምርት።',
            },
            {
              'id': 'bio_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Evolution',
              'amUnit': 'ክፍል 4: ዝግመተ ለውጥ',
              'enDesc': 'Theories of evolution, natural selection, evidence of evolution, speciation, and human evolution.',
              'amDesc': 'የዝግመተ ለውጥ ንድፈ ሃሳቦች፣ ተፈጥሯዊ ምርጫ፣ ማስረጃዎች፣ እና የሰው ልጅ አመጣጥ።',
            },
            {
              'id': 'bio_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Human Body System',
              'amUnit': 'ክፍል 5: የሰው አካል ስርዓት',
              'enDesc': 'Advanced nervous system integration, hormone regulation, immunology, and reproductive biology.',
              'amDesc': 'የላቀ የነርቭ እና የሆርሞን ቁጥጥር፣ ስነ-በሽታ መከላከል እና የስነ-ተዋልዶ ባዮሎጂ።',
            },
            {
              'id': 'bio_u6',
              'grade': 12,
              'enUnit': 'Unit 6: Climate Change',
              'amUnit': 'ክፍል 6: የአየር ንብረት ለውጥ',
              'enDesc': 'Greenhouse gases, global warming causes, impacts on ecosystems, mitigation and adaptation strategies.',
              'amDesc': 'የግሪንሃውስ ጋዞች፣ የአለም ሙቀት መጨመር፣ በስነ-ምህዳር ላይ ያሉ ተፅዕኖዎች እና መከላከያ መንገዶች።',
            },
          ];
        }
        return [];

      // ==========================================
      // PHYSICS
      // ==========================================
      case 'Physics':
        if (grade == 9) {
          return [
            {
              'id': 'phys_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Physics and Human Society',
              'amUnit': 'ክፍል 1: ፊዚክስ እና የሰው ልጅ ማህበረሰብ',
              'enDesc': 'Role of physics in daily life, technological advancement, and scientific ethics.',
              'amDesc': 'ፊዚክስ በዕለት ተዕለት ኑሮ፣ በቴክኖሎጂ እድገት እና በሳይንስ ስነ-ምግባር ውስጥ ያለው ሚና።',
            },
            {
              'id': 'phys_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Physical Quantities',
              'amUnit': 'ክፍል 2: ፊዚካዊ መጠኖች',
              'enDesc': 'Fundamental and derived units, SI system, scalar and vector quantities, and measurement.',
              'amDesc': 'መሰረታዊ እና ተወላጅ መለኪያዎች፣ የስርዓተ-መለኪያ (SI) ክፍሎች፣ ስካላር እና ቬክተር።',
            },
            {
              'id': 'phys_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Motion in a Straight Line',
              'amUnit': 'ክፍል 3: በቀጥታ መስመር ላይ የሚደረግ እንቅስቃሴ',
              'enDesc': 'Position, displacement, speed, velocity, acceleration, and motion graphs.',
              'amDesc': 'ቦታ፣ መፈናቀል፣ ፍጥነት፣ የተጣደፈ ፍጥነት እና የእንቅስቃሴ ግራፎች።',
            },
            {
              'id': 'phys_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Force, Work, Energy, and Power',
              'amUnit': 'ክፍል 4: ጉልበት፣ ስራ፣ ሃይል እና አቅም',
              'enDesc': 'Newton’s laws of motion, concept of work, kinetic and potential energy, and power calculation.',
              'amDesc': 'የኒውተን የእንቅስቃሴ ህጎች፣ ስራ፣ የእንቅስቃሴና እምቅ ሃይል እና አቅም።',
            },
            {
              'id': 'phys_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Simple Machines',
              'amUnit': 'ክፍል 5: ቀላል ማሽኖች',
              'enDesc': 'Mechanical advantage, velocity ratio, efficiency, levers, pulleys, and inclined planes.',
              'amDesc': 'የሜካኒካል ጠቀሜታ፣ የፍጥነት ሬሾ፣ ቅልጥፍና፣ ሊቨሮች፣ ፑሊዎች እና ተዳፋት ገጾች።',
            },
            {
              'id': 'phys_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Mechanical Oscillation and Sound Wave',
              'amUnit': 'ክፍል 6: ሜካኒካዊ ንዝረት እና የድምጽ ሞገድ',
              'enDesc': 'Periodic motion, simple pendulum, wave properties, sound propagation, and pitch.',
              'amDesc': 'ወቅታዊ እንቅስቃሴ፣ ፔንዱለም፣ የሞገድ ባህሪያት፣ የድምጽ ስርጭት እና ድምጽ ጥራት።',
            },
            {
              'id': 'phys_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Temperature and Thermometer',
              'amUnit': 'ክፍል 7: የሙቀት መጠን እና ቴርሞሜትር',
              'enDesc': 'Thermal equilibrium, temperature scales (Celsius, Kelvin, Fahrenheit), and thermal expansion.',
              'amDesc': 'የሙቀት ሚዛን፣ የሙቀት መለኪያ ስኬሎች እና የሙቀት መስፋፋት።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'phys_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Vector Quantities',
              'amUnit': 'ክፍል 1: ቬክተር መጠኖች',
              'enDesc': 'Vectors in two dimensions, vector resolution into components, and vector addition.',
              'amDesc': 'ባለ ሁለት አቅጣጫ ቬክተሮች፣ ቬክተሮችን መከፋፈል እና የቬክተር ድምር ስሌቶች።',
            },
            {
              'id': 'phys_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Uniformly Accelerated Motion',
              'amUnit': 'ክፍል 2: ወጥ የተፋጠነ እንቅስቃሴ',
              'enDesc': 'Kinematics equations, free fall under gravity, and projectile motion trajectories.',
              'amDesc': 'የተፋጠነ እንቅስቃሴ እኩልታዎች፣ ነፃ መውደቅ እና የፕሮጀክታይል እንቅስቃሴ።',
            },
            {
              'id': 'phys_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Elasticity and Static Equilibrium of Rigid Body',
              'amUnit': 'ክፍል 3: የመለጠጥ ባህሪ እና የጠንካራ አካላት ሚዛን',
              'enDesc': 'Hooke\'s law, stress, strain, Young\'s modulus, torque, and static equilibrium conditions.',
              'amDesc': 'የሁክ ህግ፣ ውጥረት (Stress)፣ ስትሬን (Strain)፣ ቶርክ እና የስታቲክ ሚዛን ሁኔታዎች።',
            },
            {
              'id': 'phys_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Static and Current Electricity',
              'amUnit': 'ክፍል 4: ስታቲክ እና ተንቀሳቃሽ ኤሌክትሪክ',
              'enDesc': 'Electrostatic forces, Coulomb\'s law, electric current, Ohm\'s law, resistance, and DC circuits.',
              'amDesc': 'የኤሌክትሮስታቲክ ሃይሎች፣ የኩሎምብ ህግ፣ የኦህም ህግ፣ የመቋቋም አቅም እና ዲሲ ሰርኪዩት።',
            },
            {
              'id': 'phys_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Magnetism',
              'amUnit': 'ክፍል 5: ማግኔቲዝም',
              'enDesc': 'Magnetic fields, magnetic forces on charges and currents, and electromagnetism.',
              'amDesc': 'የማግኔት መስክ፣ በማግኔት የሚፈጠር ሃይል እና ኤሌክትሮማግኔቲዝም።',
            },
            {
              'id': 'phys_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Electromagnetic Waves and Geometrical Optics',
              'amUnit': 'ክፍል 6: ኤሌክትሮማግኔቲክ ሞገዶች እና ጂኦሜትሪካል ኦፕቲክስ',
              'enDesc': 'Electromagnetic spectrum, reflection, refraction, lenses, mirrors, and optical instruments.',
              'amDesc': 'የኤሌክትሮማግኔቲክ ስፔክትረም፣ ነጸብራቅ፣ ስብራት፣ ሌንሶች፣ መስታወቶች እና ኦፕቲካል መሳሪያዎች።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'phys_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Properties of Matter',
              'amUnit': 'ክፍል 1: የማተር ባህሪያት',
              'enDesc': 'Elastic properties of solids, stress-strain curves, shear modulus, and bulk modulus.',
              'amDesc': 'የጠንካራ አካላት የመለጠጥ ባህሪያት፣ የውጥረት ግራፎች እና ሞጁለስ።',
            },
            {
              'id': 'phys_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Fluid Mechanics',
              'amUnit': 'ክፍል 2: የፈሳሽ መካኒክስ',
              'enDesc': 'Fluid statics, Pascal\'s principle, Archimedes\' principle, continuity equation, and Bernoulli\'s equation.',
              'amDesc': 'የፈሳሽ ስታቲክስ፣ የፓስካል ህግ፣ የአርኪሜድስ መርህ እና የበርኑሊ እኩልታ።',
            },
            {
              'id': 'phys_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Heat and Thermodynamics',
              'amUnit': 'ክፍል 3: ሙቀት እና ቴርሞዳይናሚክስ',
              'enDesc': 'Specific heat capacity, latent heat, ideal gas laws, internal energy, and laws of thermodynamics.',
              'amDesc': 'የተወሰነ የሙቀት አቅም፣ የጋዝ ህጎች፣ የውስጥ ሃይል እና የቴርሞዳይናሚክስ ህጎች።',
            },
            {
              'id': 'phys_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Oscillations and Waves',
              'amUnit': 'ክፍል 4: ንዝረቶች እና ሞገዶች',
              'enDesc': 'Simple harmonic motion, wave mechanics, standing waves, Doppler effect, and resonance.',
              'amDesc': 'ቀላል ሃርሞኒክ እንቅስቃሴ፣ የሞገድ መካኒክስ፣ ቋሚ ሞገዶች እና የዶፕለር ተፅዕኖ።',
            },
            {
              'id': 'phys_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Electrostatics',
              'amUnit': 'ክፍል 5: ኤሌክትሮስታቲክስ',
              'enDesc': 'Electric field intensity, Gauss\'s law, electric potential energy, capacitance, and dielectrics.',
              'amDesc': 'የኤሌክትሪክ መስክ ጥንካሬ፣ የጋውስ ህግ፣ የኤሌክትሪክ ፖቴንሻል እና ካፓሲተሮች።',
            },
            {
              'id': 'phys_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Current Electricity',
              'amUnit': 'ክፍል 6: ተንቀሳቃሽ ኤሌክትሪክ',
              'enDesc': 'Kirchhoff\'s rules, Wheatstone bridge, potentiometer, electrical power, and circuit networks.',
              'amDesc': 'የኪርቾፍ ህጎች፣ ዊትስቶን ብሪጅ፣ የኤሌክትሪክ ሃይል ስሌቶች እና ሰርኪዩቶች።',
            },
            {
              'id': 'phys_u7',
              'grade': 11,
              'enUnit': 'Unit 7: Electromagnetic Induction',
              'amUnit': 'ክፍል 7: ኤሌክትሮማግኔቲክ ኢንዳክሽን',
              'enDesc': 'Magnetic flux, Faraday\'s law, Lenz\'s law, self and mutual inductance, AC generators, and transformers.',
              'amDesc': 'ማግኔቲክ ፍለክስ፣ የፋራዳይ ህግ፣ የሌንዝ ህግ፣ ራስ እና የጋራ ኢንዳክሽን፣ እና ትራንስፎርመሮች።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'phys_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Electromagnetic Induction',
              'amUnit': 'ክፍል 1: ኤሌክትሮማግኔቲክ ኢንዳክሽን',
              'enDesc': 'Motional EMF, Faraday\'s law, Lenz\'s law, inductance, AC circuits, and power transmission.',
              'amDesc': 'ኢንዳክሽን፣ የፋራዳይ ህግ፣ የሌንዝ ህግ፣ የኤሲ (AC) ሰርኪዩቶች እና የሃይል ማስተላለፊያ።',
            },
            {
              'id': 'phys_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Electromagnetic Waves',
              'amUnit': 'ክፍል 2: ኤሌክትሮማግኔቲክ ሞገዶች',
              'enDesc': 'Maxwell\'s equations, propagation of EM waves, wave optics, polarization, and diffraction.',
              'amDesc': 'የማክስዌል እኩልታዎች፣ የኤሌክትሮማግኔቲክ ሞገድ ስርጭት፣ ፖላራይዜሽን እና ዲፍራክሽን።',
            },
            {
              'id': 'phys_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Atomic Physics',
              'amUnit': 'ክፍል 3: አቶሚክ ፊዚክስ',
              'enDesc': 'Photoelectric effect, Bohr\'s model of hydrogen atom, atomic energy levels, and X-rays.',
              'amDesc': 'ፎቶኤሌክትሪክ ተፅዕኖ፣ የቦህር አቶሚክ ሞዴል፣ የሃይል እርከኖች እና ኤክስ-ሬይ።',
            },
            {
              'id': 'phys_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Nuclear Physics',
              'amUnit': 'ክፍል 4: ኒውክሌር ፊዚክስ',
              'enDesc': 'Nuclear structure, mass defect, binding energy, radioactive decay, nuclear fission, and fusion.',
              'amDesc': 'የኒውክሊየስ መዋቅር፣ አስገዳጅ ሃይል፣ ራዲዮአክቲቪቲ፣ ፊሽን እና ፊውዥን።',
            },
            {
              'id': 'phys_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Electronics',
              'amUnit': 'ክፍል 5: ኤሌክትሮኒክስ',
              'enDesc': 'Semiconductors, p-n junction diodes, rectification, transistors, integrated circuits, and logic gates.',
              'amDesc': 'ሴሚኮንዳክተሮች፣ ፒ-ኤን ዳዮዶች፣ ትራንዚስተሮች፣ የተቀናጁ ሰርኪዩቶች እና ሎጂክ ጌቶች።',
            },
          ];
        }
        return [];

      // ==========================================
      // CHEMISTRY
      // ==========================================
      case 'Chemistry':
        if (grade == 9) {
          return [
            {
              'id': 'chem_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Chemistry and Its Importance',
              'amUnit': 'ክፍል 1: ኬሚስትሪ እና ጠቀሜታው',
              'enDesc': 'Definition, branches of chemistry, and applications in industry, agriculture, and medicine.',
              'amDesc': 'የኬሚስትሪ ምንነት፣ ቅርንጫፎች እና በግብርና፣ ህክምናና ኢንዱስትሪ ውስጥ ያለው ጠቀሜታ።',
            },
            {
              'id': 'chem_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Measurements and Scientific Methods',
              'amUnit': 'ክፍል 2: መለኪያዎች እና ሳይንሳዊ ዘዴዎች',
              'enDesc': 'Laboratory safety, scientific measurements, significant figures, and unit conversions.',
              'amDesc': 'የቤተ-ሙከራ ደህንነት፣ ሳይንሳዊ መለኪያዎች እና የመለኪያ ክፍሎች ልውውጥ።',
            },
            {
              'id': 'chem_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Structure of the Atom',
              'amUnit': 'ክፍል 3: የአቶም መዋቅር',
              'enDesc': 'Subatomic particles (protons, neutrons, electrons), atomic models, and electron arrangement.',
              'amDesc': 'የአቶም ንዑሳን ቅንጣቶች፣ የአቶሚክ ሞዴሎች እና የኤሌክትሮን አቀማመጥ።',
            },
            {
              'id': 'chem_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Periodic Classification of Elements',
              'amUnit': 'ክፍል 4: የንጥረ ነገሮች ወቅታዊ ምደባ',
              'enDesc': 'Modern periodic table, periods, groups, periodic trends (atomic size, ionization energy).',
              'amDesc': 'ወቅታዊ ሰንጠረዥ፣ ግሩፖች፣ ፒሪየዶች እና ወቅታዊ ባህሪያት (Periodic Trends)።',
            },
            {
              'id': 'chem_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Chemical Bonding',
              'amUnit': 'ክፍል 5: ኬሚካዊ ትስስር',
              'enDesc': 'Ionic bonding, covalent bonding, metallic bonding, and Lewis structures of molecules.',
              'amDesc': 'አዮኒክ ትስስር፣ ኮቫለንት ትስስር፣ ሜታሊክ ትስስር እና የሌዊስ መዋቅር።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'chem_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Chemical Reactions and Stoichiometry',
              'amUnit': 'ክፍል 1: ኬሚካዊ ምላሾች እና ስቶይኪዮሜትሪ',
              'enDesc': 'Types of reactions, balancing equations, mole concept, stoichiometry, and limiting reactants.',
              'amDesc': 'የኬሚካዊ ምላሾች አይነቶች፣ እኩልታዎችን ማመጣጠን፣ የሞል ጽንሰ-ሀሳብ እና ስቶይኪዮሜትሪ።',
            },
            {
              'id': 'chem_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Solutions',
              'amUnit': 'ክፍል 2: መፍትሄዎች',
              'enDesc': 'Solutes, solvents, solubility, concentration units (molarity, mass %), and colligative properties.',
              'amDesc': 'ሟሚ እና አሟሚ፣ የመሟሟት ባህሪ፣ የትኩረት መለኪያዎች (ሞላሪቲ) እና የሶሉሽን ባህሪያት።',
            },
            {
              'id': 'chem_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Important Inorganic Compounds',
              'amUnit': 'ክፍል 3: አስፈላጊ ኢ-ኦርጋኒክ ውህዶች',
              'enDesc': 'Oxides, acids, bases, salts, pH scale, neutralization, and industrial uses.',
              'amDesc': 'ኦክሳይዶች፣ አሲዶች፣ ቤዞች፣ ጨዎች፣ የፒኤች (pH) መለኪያ እና ገለልተኛ መሆን ሂደቶች።',
            },
            {
              'id': 'chem_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Energy Changes and Electro-Chemistry',
              'amUnit': 'ክፍል 4: የሃይል ለውጦች እና ኤሌክትሮኬሚስትሪ',
              'enDesc': 'Exothermic and endothermic reactions, enthalpy, redox reactions, galvanic cells, and electrolysis.',
              'amDesc': 'ኤክሶተርሚክና ኢንዶተርሚክ ምላሾች፣ ሬዶክስ ምላሾች፣ የጋልቫኒክ ሴሎች እና ኤሌክትሮሊሲስ።',
            },
            {
              'id': 'chem_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Metals and Non-Metals',
              'amUnit': 'ክፍል 5: ብረቶች እና ኢ-ብረቶች',
              'enDesc': 'Physical and chemical properties of metals, extraction metallurgy, alloys, and non-metals.',
              'amDesc': 'የብረቶችና ኢ-ብረቶች ባህሪያት፣ የብረት ማውጣት ዘዴዎች፣ ቅይጥ ብረቶች (Alloys)።',
            },
            {
              'id': 'chem_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Hydrocarbons and Their Natural Sources',
              'amUnit': 'ክፍል 6: ሃይድሮካርቦኖች እና የተፈጥሮ ምንጮቻቸው',
              'enDesc': 'Alkanes, alkenes, alkynes, nomenclature, petroleum refining, fractional distillation, and uses.',
              'amDesc': 'አልኬን፣ አልኪን፣ አልካይን፣ የፔትሮሊየም ማጣራት እና የሃይድሮካርቦኖች አጠቃቀም።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'chem_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Atomic Structure And Periodic Properties Of The Elements',
              'amUnit': 'ክፍል 1: የአቶም መዋቅር እና ወቅታዊ ባህሪያት',
              'enDesc': 'Quantum mechanical model, quantum numbers, electronic configurations, and periodic trends.',
              'amDesc': 'የኳንተም ሜካኒካል ሞዴል፣ የኳንተም ቁጥሮች፣ የኤሌክትሮን ምደባ እና ወቅታዊ ባህሪያት።',
            },
            {
              'id': 'chem_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Chemical Bonding',
              'amUnit': 'ክፍል 2: ኬሚካዊ ትስስር',
              'enDesc': 'Valence bond theory, hybridization, molecular geometry (VSEPR), and intermolecular forces.',
              'amDesc': 'ሞለኪውላር ጂኦሜትሪ (VSEPR)፣ ሃይብሪዳይዜሽን እና ኢንተር-ሞለኪውላር ሃይሎች።',
            },
            {
              'id': 'chem_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Physical State Of Matter',
              'amUnit': 'ክፍል 3: የማተር አካላዊ ሁኔታዎች',
              'enDesc': 'Kinetic molecular theory, ideal gas laws, real gas deviations, liquid state, and crystal solids.',
              'amDesc': 'የጋዞች ኪነቲክ ቲዎሪ፣ የጋዝ ህጎች፣ የፈሳሽ እና የጠንካራ አካላት ክሪስታል መዋቅር።',
            },
            {
              'id': 'chem_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Chemical Kinetics',
              'amUnit': 'ክፍል 4: ኬሚካዊ ኪነቲክስ',
              'enDesc': 'Rates of reaction, rate laws, order of reaction, Arrhenius equation, and catalysis.',
              'amDesc': 'የምላሽ ፍጥነት፣ የፍጥነት ህጎች፣ የአሬኒየስ እኩልታ እና የካታላይሲስ ተግባር።',
            },
            {
              'id': 'chem_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Chemical Equilibrium',
              'amUnit': 'ክፍል 5: ኬሚካዊ ሚዛን',
              'enDesc': 'Equilibrium constant (Kc, Kp), Le Chatelier\'s principle, acid-base equilibria, and solubility product (Ksp).',
              'amDesc': 'የሚዛን ቋሚ (Kc, Kp)፣ የሌ ሻተሌየር መርህ፣ የአሲድ-ቤዝ ሚዛን እና የመሟሟት ቋሚ (Ksp)።',
            },
            {
              'id': 'chem_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Some Important Oxygen-containing Organic Compounds',
              'amUnit': 'ክፍል 6: አስፈላጊ ኦክሲጅን የያዙ ኦርጋኒክ ውህዶች',
              'enDesc': 'Alcohols, phenols, ethers, aldehydes, ketones, carboxylic acids, and esters.',
              'amDesc': 'አልኮሆሎች፣ ፌኖሎች፣ ኢተሮች፣ አልዲሃይዶች፣ ኬቶኖች፣ ካርቦክሲሊክ አሲዶች እና አስተሮች።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'chem_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Chemical Thermodynamics',
              'amUnit': 'ክፍል 1: ኬሚካዊ ቴርሞዳይናሚክስ',
              'enDesc': 'Enthalpy, entropy, Gibbs free energy, and reaction spontaneity laws.',
              'amDesc': 'ኤንታልፒ፣ ኢንትሮፒ፣ የጊብስ ነፃ ሃይል እና የምላሽ ድንገተኛነት ህጎች።',
            },
            {
              'id': 'chem_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Chemical Kinetics',
              'amUnit': 'ክፍል 2: ኬሚካዊ ኪነቲክስ',
              'enDesc': 'Integrated rate laws, half-life, reaction mechanisms, and collision theory.',
              'amDesc': 'የተቀናጁ የፍጥነት ህጎች፣ የግማሽ ህይወት ስሌት እና የምላሽ ዘዴዎች።',
            },
            {
              'id': 'chem_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Chemical Equilibrium',
              'amUnit': 'ክፍል 3: ኬሚካዊ ሚዛን',
              'enDesc': 'Heterogeneous equilibrium, buffer solutions, common ion effect, and hydrolysis.',
              'amDesc': 'የተለያዩ ሚዛኖች፣ ባፈር ሶሉሽኖች፣ የኮመን አዮን ተፅዕኖ እና ሃይድሮሊሲስ።',
            },
            {
              'id': 'chem_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Electrochemistry',
              'amUnit': 'ክፍል 4: ኤሌክትሮኬሚስትሪ',
              'enDesc': 'Standard reduction potentials, Nernst equation, electrolytic cells, and battery systems.',
              'amDesc': 'መደበኛ ኤሌክትሮድ ፖቴንሻል፣ ኔርነስት እኩልታ፣ ኤሌክትሮላይቲክ ሴሎች እና ባትሪዎች።',
            },
            {
              'id': 'chem_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Environmental Chemistry',
              'amUnit': 'ክፍል 5: የአካባቢ ኬሚስትሪ',
              'enDesc': 'Atmospheric pollutants, ozone depletion, greenhouse effect, and green chemistry.',
              'amDesc': 'የከባቢ አየር ብክለት፣ የኦዞን መመናመን፣ የግሪንሃውስ ተፅዕኖ እና አረንጓዴ ኬሚስትሪ።',
            },
          ];
        }
        return [];

      // ==========================================
      // HISTORY
      // ==========================================
      case 'History':
        if (grade == 9) {
          return [
            {
              'id': 'hist_u1',
              'grade': 9,
              'enUnit': 'Unit 1: The Discipline of History and Human Evolution',
              'amUnit': 'ክፍል 1: የታሪክ ትምህርት እና የሰው ልጅ ዝግመተ ለውጥ',
              'enDesc': 'Nature and sources of history, human origin, and early stone age tools in East Africa.',
              'amDesc': 'የታሪክ ምንነትና ምንጮች፣ የሰው ልጅ አመጣጥ እና የድንጋይ ዘመን መሳሪያዎች።',
            },
            {
              'id': 'hist_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Ancient World Civilizations up to c. 500 AD',
              'amUnit': 'ክፍል 2: ጥንታዊ የአለም ስልጣኔዎች እስከ 500 ድ.ል',
              'enDesc': 'Ancient civilizations of Egypt, Mesopotamia, Indus Valley, China, Greece, and Rome.',
              'amDesc': 'የግብፅ፣ ሜሶፖታሚያ፣ ኢንደስ ሸለቆ፣ ቻይና፣ ግሪክ እና ሮም ጥንታዊ ስልጣኔዎች።',
            },
            {
              'id': 'hist_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Peoples and States in Ethiopia and the Horn to the End of 13th Century',
              'amUnit': 'ክፍል 3: ህዝቦች እና መንግስታት በኢትዮጵያ እና በቀንድ እስከ 13ኛው መ/ክ/ዘ መጨረሻ',
              'enDesc': 'Punt, Da\'amat, Aksumite kingdom, Zagwe dynasty, trade routes, and religion.',
              'amDesc': 'ፑንት፣ ዳአማት፣ የአክሱም ስልጣኔ፣ የዛግዌ ስርወ-መንግስት እና የንግድ መስመሮች።',
            },
            {
              'id': 'hist_u4',
              'grade': 9,
              'enUnit': 'Unit 4: The Middle Ages and Early Modern World, c. 500–1750s',
              'amUnit': 'ክፍል 4: የመካከለኛው ዘመን እና ቀደምት ዘመናዊ አለም፣ 500–1750ዎች',
              'enDesc': 'Feudalism in Europe, Islamic caliphates, Ottoman empire, Renaissance, and voyages.',
              'amDesc': 'ፊውዳሊዝም፣ የእስልምና ኸሊፋዎች፣ የኦቶማን ግዛት እና የታላላቅ የባህር ጉዞዎች ዘመን።',
            },
            {
              'id': 'hist_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Peoples and States of Africa to 1500',
              'amUnit': 'ክፍል 5: የአፍሪካ ህዝቦች እና መንግስታት እስከ 1500',
              'enDesc': 'Ancient African states: Ghana, Mali, Songhai, Great Zimbabwe, and Swahili city-states.',
              'amDesc': 'ጋና፣ ማሊ፣ ሶንግሃይ፣ ታላቋ ዚምባብዌ እና የስዋሂሊ የባህር ዳርቻ ስልጣኔዎች።',
            },
            {
              'id': 'hist_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Africa and the Outside World 1500–1880s',
              'amUnit': 'ክፍል 6: አፍሪካ እና የውጭው አለም 1500–1880ዎች',
              'enDesc': 'Transatlantic slave trade, European commercial expansion, and early colonial contacts.',
              'amDesc': 'የአትላንቲክ የባሪያ ንግድ፣ የአውሮፓውያን የንግድ መስፋፋት እና የመጀመሪያ ቅኝ ግዛት ግንኙነቶች።',
            },
            {
              'id': 'hist_u7',
              'grade': 9,
              'enUnit': 'Unit 7: States, Principalities, Population Movements & Interactions in Ethiopia, 13th to Mid-16th C.',
              'amUnit': 'ክፍል 7: መንግስታት፣ የህዝብ እንቅስቃሴዎች እና መስተጋብሮች በኢትዮጵያ፣ 13ኛው–16ኛው መ/ክ/ዘ',
              'enDesc': 'Solomonic dynasty restoration, Muslim sultanates (Ifat, Adal), and territorial interactions.',
              'amDesc': 'የሰለሞናዊ ስርወ-መንግስት መመለስ፣ የሙስሊም ሱልጣኔቶች (ኢፋት፣ አዳል) እና ግንኙነቶች።',
            },
            {
              'id': 'hist_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Political, Social, and Economic Processes in Ethiopia, Mid-16th to Mid-19th C.',
              'amUnit': 'ክፍል 8: ፖለቲካዊ፣ ማህበራዊ እና ኢኮኖሚያዊ ሂደቶች በኢትዮጵያ፣ 16ኛው–19ኛው መ/ክ/ዘ',
              'enDesc': 'Oromo population movement, Gadaa system, Gondar period, and Zemene Mesafint.',
              'amDesc': 'የኦሮሞ ህዝብ እንቅስቃሴ፣ የገዳ ስርዓት፣ የጎንደር ዘመን እና የዘመነ መሳፍንት ታሪክ።',
            },
            {
              'id': 'hist_u9',
              'grade': 9,
              'enUnit': 'Unit 9: The Age of Revolutions, 1750s–1815',
              'amUnit': 'ክፍል 9: የአብዮቶች ዘመን፣ 1750ዎች–1815',
              'enDesc': 'Industrial Revolution, American Revolution, French Revolution, and Napoleonic era.',
              'amDesc': 'የኢንዱስትሪ አብዮት፣ የአሜሪካ አብዮት፣ የፈረንሳይ አብዮት እና የናፖሊዮን ዘመን።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'hist_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Development of Capitalism and Nationalism (1815–1914)',
              'amUnit': 'ክፍል 1: የካፒታሊዝም እና የብሔርተኝነት እድገት (1815–1914)',
              'enDesc': 'Industrial capitalism, unification of Italy and Germany, and European imperial expansion.',
              'amDesc': 'የኢንዱስትሪ ካፒታሊዝም፣ የጣሊያን እና ጀርመን ውህደት እና የአውሮፓ ኢምፔሪያሊዝም።',
            },
            {
              'id': 'hist_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Africa and the Colonial Experience (1880s–1960s)',
              'amUnit': 'ክፍል 2: አፍሪካ እና የቅኝ አገዛዝ ልምድ (1880ዎች–1960ዎች)',
              'enDesc': 'Scramble for Africa, Berlin Conference, colonial administrative policies, and resistance.',
              'amDesc': 'የአፍሪካ ቅርጫ፣ የበርሊን ጉባኤ፣ የቅኝ ግዛት አስተዳደሮች እና ፀረ-ቅኝ ግዛት ትግል።',
            },
            {
              'id': 'hist_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Ethiopia in the Era of Menelik II and Iyasu',
              'amUnit': 'ክፍል 3: ኢትዮጵያ በዳግማዊ ምኒልክ እና እያሱ ዘመን',
              'enDesc': 'Territorial reunification, Battle of Adwa, early modernization, and reforms of Lij Iyasu.',
              'amDesc': 'የግዛት አንድነት ማጠናከር፣ የአድዋ ድል፣ የመጀመሪያ ዘመናዊ ተቋማት እና የልጅ እያሱ ዘመን።',
            },
            {
              'id': 'hist_u4',
              'grade': 10,
              'enUnit': 'Unit 4: The First World War and Its Consequences',
              'amUnit': 'ክፍል 4: አንደኛው የአለም ጦርነት እና ውጤቶቹ',
              'enDesc': 'Causes, course, Treaty of Versailles, League of Nations, and geopolitical aftermath.',
              'amDesc': 'የአንደኛው የአለም ጦርነት መንስኤዎች፣ የቨርሳይ ስምምነት እና የሊግ ኦፍ ኔሽንስ ምስረታ።',
            },
            {
              'id': 'hist_u5',
              'grade': 10,
              'enUnit': 'Unit 5: The Interwar Period',
              'amUnit': 'ክፍል 5: በጦርነቶቹ መካከል ያለው ወቅት',
              'enDesc': 'Great Depression, rise of Fascism in Italy and Nazism in Germany, and militarism.',
              'amDesc': 'ታላቁ የኢኮኖሚ ድቀት፣ የፋሺዝም እና ናዚዝም መነሳት እና ወታደራዊ ዝግጅቶች።',
            },
            {
              'id': 'hist_u6',
              'grade': 10,
              'enUnit': 'Unit 6: The Second World War',
              'amUnit': 'ክፍል 6: ሁለተኛው የአለም ጦርነት',
              'enDesc': 'Outbreak of WWII, Axis vs Allies, major battles, Holocaust, and United Nations formation.',
              'amDesc': 'የሁለተኛው የአለም ጦርነት፣ የአክሲስና አላይድ ሃይሎች፣ ሆሎኮስት እና የተመድ ምስረታ።',
            },
            {
              'id': 'hist_u7',
              'grade': 10,
              'enUnit': 'Unit 7: Ethiopia from 1941 to 1974',
              'amUnit': 'ክፍል 7: ኢትዮጵያ ከ1941 እስከ 1974',
              'enDesc': 'Post-restoration Haile Selassie government, modernization, peasant revolts, and student movement.',
              'amDesc': 'የድህረ-ድል የቀዳማዊ ኃይለ ሥላሴ ዘመን፣ የገበሬዎች አመጽ እና የተማሪዎች ንቅናቄ።',
            },
            {
              'id': 'hist_u8',
              'grade': 10,
              'enUnit': 'Unit 8: The Cold War and Its Consequences',
              'amUnit': 'ክፍል 8: የቀዝቃዛው ጦርነት እና ውጤቶቹ',
              'enDesc': 'US vs USSR ideological rivalry, NATO, Warsaw Pact, proxy wars, and non-aligned movement.',
              'amDesc': 'የአሜሪካ እና የሶቪየት ፍጥጫ፣ ኔቶ፣ ዋርሶ ፓክት፣ ተኪ ጦርነቶች እና የገለልተኞች ንቅናቄ።',
            },
            {
              'id': 'hist_u9',
              'grade': 10,
              'enUnit': 'Unit 9: Major Global Developments Since 1991',
              'amUnit': 'ክፍል 9: ዋና ዋና አለም አቀፍ እድገቶች ከ1991 ጀምሮ',
              'enDesc': 'Collapse of USSR, globalization, information age, regional integration, and terrorism.',
              'amDesc': 'የሶቪየት ህብረት መፍረስ፣ ግሎባላይዜሽን፣ የኢንፎርሜሽን ዘመን እና አለም አቀፍ ተግዳሮቶች።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'hist_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Early Human History',
              'amUnit': 'ክፍል 1: ቀደምት የሰው ልጅ ታሪክ',
              'enDesc': 'Prehistoric archaeological evidence, hominid evolution in Africa, and Neolithic revolution.',
              'amDesc': 'የቅድመ-ታሪክ አርኪዮሎጂ ማስረጃዎች፣ የሰው ልጅ ዝግመተ ለውጥ እና የኒዮሊቲክ አብዮት።',
            },
            {
              'id': 'hist_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Ancient Civilizations',
              'amUnit': 'ክፍል 2: ጥንታዊ ስልጣኔዎች',
              'enDesc': 'Nile Valley, Mesopotamian, Greco-Roman classical heritage, and ancient Asian empires.',
              'amDesc': 'የአባይ ሸለቆ፣ የሜሶፖታሚያ፣ የግሪክ-ሮማን እና የእስያ ጥንታዊ ስልጣኔዎች።',
            },
            {
              'id': 'hist_u3',
              'grade': 11,
              'enUnit': 'Unit 3: The Middle Ages',
              'amUnit': 'ክፍል 3: የመካከለኛው ዘመን',
              'enDesc': 'Byzantine empire, Golden Age of Islam, feudal Europe institutions, and Crusades.',
              'amDesc': 'የባይዛንታይን ግዛት፣ የእስልምና ወርቃማ ዘመን፣ የፊውዳል አውሮፓ እና የመስቀል ጦርነቶች።',
            },
            {
              'id': 'hist_u4',
              'grade': 11,
              'enUnit': 'Unit 4: The Age of Exploration and Expansion',
              'amUnit': 'ክፍል 4: የዳሰሳ እና የማስፋፊያ ዘመን',
              'enDesc': 'Renaissance, Reformation, maritime exploration, and worldwide commercial networks.',
              'amDesc': 'ህዳሴ (Renaissance)፣ ሪፎርሜሽን፣ የባህር ዳሰሳ ጉዞዎች እና አለም አቀፍ ንግድ።',
            },
            {
              'id': 'hist_u5',
              'grade': 11,
              'enUnit': 'Unit 5: The Ottoman Empire',
              'amUnit': 'ክፍል 5: የኦቶማን ኢምፓየር',
              'enDesc': 'Rise of Ottomans, conquest of Constantinople, institutions, expansion in Africa, and decline.',
              'amDesc': 'የኦቶማን መነሳት፣ የቁስጥንጥንያ መያዝ፣ በአፍሪካና አውሮፓ መስፋፋት እና ውድቀት።',
            },
            {
              'id': 'hist_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Africa in the Early Modern Period',
              'amUnit': 'ክፍል 6: አፍሪካ በቀደምት ዘመናዊ ወቅት',
              'enDesc': 'Kingdoms of Benin, Kongo, Oyo, Indian Ocean trade networks, and slave trade impacts.',
              'amDesc': 'የቤኒን፣ ኮንጎ፣ ኦዮ መንግስታት፣ የህንድ ውቅያኖስ ንግድ እና የባሪያ ንግድ ተፅዕኖ።',
            },
            {
              'id': 'hist_u7',
              'grade': 11,
              'enUnit': 'Unit 7: Ethiopia from the 13th to the 16th Century',
              'amUnit': 'ክፍል 7: ኢትዮጵያ ከ13ኛው እስከ 16ኛው መቶ ክፍለ ዘመን',
              'enDesc': 'Medieval Solomonic state, Christian-Muslim conflicts, Ahmad Gragn wars, and cultural life.',
              'amDesc': 'የመካከለኛው ዘመን ሰለሞናዊ መንግስት፣ የአህመድ ግራኝ ጦርነት እና ባህላዊ እድገቶች።',
            },
            {
              'id': 'hist_u8',
              'grade': 11,
              'enUnit': 'Unit 8: Ethiopia from the 16th to the 18th Century',
              'amUnit': 'ክፍል 8: ኢትዮጵያ ከ16ኛው እስከ 18ኛው መቶ ክፍለ ዘመን',
              'enDesc': 'Oromo population movement, Gadaa democracy, Jesuit mission, and Gondar period architecture.',
              'amDesc': 'የኦሮሞ ህዝብ እንቅስቃሴ፣ የገዳ ዲሞክራሲ፣ የኢየሱሳውያን ተልዕኮ እና የጎንደር ቤተ-መንግስታት።',
            },
            {
              'id': 'hist_u9',
              'grade': 11,
              'enUnit': 'Unit 9: Ethiopia in the 19th Century',
              'amUnit': 'ክፍል 9: ኢትዮጵያ በ19ኛው መቶ ክፍለ ዘመን',
              'enDesc': 'Zemene Mesafint conclusion, state reunification by Tewodros II and Yohannes IV, and foreign aggression.',
              'amDesc': 'የዘመነ መሳፍንት ማብቂያ፣ የቴዎድሮስና ዮሐንስ ሀገር አንድ የማድረግ ጥረት እና የውጭ ወረራ።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'hist_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Development of Capitalism and Nationalism from 1815 to 1914',
              'amUnit': 'ክፍል 1: የካፒታሊዝም እና ብሔርተኝነት እድገት ከ1815 እስከ 1914',
              'enDesc': 'Industrialization, 1848 revolutions, European nationalism, and colonial scramble.',
              'amDesc': 'የኢንዱስትሪ መስፋፋት፣ የ1848 አብዮቶች፣ የአውሮፓ ብሔርተኝነት እና የቅኝ ግዛት ሽሚያ።',
            },
            {
              'id': 'hist_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Africa and the Colonial Experience (1880s – 1960s)',
              'amUnit': 'ክፍል 2: አፍሪካ እና የቅኝ ግዛት ልምድ (1880ዎች–1960ዎች)',
              'enDesc': 'Colonial systems, economic exploitation, African resistance, and decolonization movements.',
              'amDesc': 'የቅኝ ግዛት ስርአቶች፣ ኢኮኖሚያዊ ብዝበዛ፣ የአፍሪካውያን ተጋድሎ እና የነጻነት ንቅናቄዎች።',
            },
            {
              'id': 'hist_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Social, Economic, and Political Developments in Ethiopia, Mid, 19th C. to 1941',
              'amUnit': 'ክፍል 3: ማህበራዊ፣ ኢኮኖሚያዊ እና ፖለቲካዊ እድገቶች በኢትዮጵያ 19ኛው መ/ክ/ዘ–1941',
              'enDesc': 'Menelik II’s modernization, Battle of Adwa, Ras Teferi\'s rise, Italian invasion, and patriotic resistance.',
              'amDesc': 'የዳግማዊ ምኒልክ ዘመናዊነት፣ የአድዋ ድል፣ የራስ ተፈሪ መነሳት፣ የጣሊያን ወረራ እና የአርበኞች ተጋድሎ።',
            },
            {
              'id': 'hist_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Society and Politics in the Age of World Wars, 1914 - 1945',
              'amUnit': 'ክፍል 4: ማህበረሰብ እና ፖለቲካ በአለም ጦርነቶች ዘመን 1914–1945',
              'enDesc': 'World wars impact, Russian revolution, interwar crises, totalitarian regimes, and WWII aftermath.',
              'amDesc': 'የአለም ጦርነቶች ተፅዕኖ፣ የሩሲያ አብዮት፣ በጦርነቱ መሀል ያሉ ቀውሶች እና አምባገነን ስርአቶች።',
            },
            {
              'id': 'hist_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Global and Regional Developments Since 1945',
              'amUnit': 'ክፍል 5: አለም አቀፍ እና ቀጠናዊ እድገቶች ከ1945 ጀምሮ',
              'enDesc': 'UN formation, Cold War conflicts, Asian and African decolonization, and regional organizations.',
              'amDesc': 'የተመድ ምስረታ፣ የቀዝቃዛው ጦርነት ግጭቶች፣ የእስያና አፍሪካ ነጻ መውጣት እና ቀጠናዊ ድርጅቶች።',
            },
            {
              'id': 'hist_u6',
              'grade': 12,
              'enUnit': 'Unit 6: Ethiopia: Internal Developments and External Influences from 1941 to 1991',
              'amUnit': 'ክፍል 6: ኢትዮጵያ፡ ውስጣዊ እድገቶች እና ውጫዊ ተፅዕኖዎች 1941–1991',
              'enDesc': 'Haile Selassie restoration, 1974 revolution, Derg socialist regime, Red Terror, civil war, and 1991 fall.',
              'amDesc': 'የቀዳማዊ ኃይለ ሥላሴ ዘመን፣ የ1966 አብዮት፣ የደርግ የሶሻሊዝም ስርዓት፣ የእርስ በርስ ጦርነት እና ውድቀቱ።',
            },
            {
              'id': 'hist_u7',
              'grade': 12,
              'enUnit': 'Unit 7: Africa since the 1960s',
              'amUnit': 'ክፍል 7: አፍሪካ ከ1960ዎቹ ጀምሮ',
              'enDesc': 'Post-colonial governance, OAU/AU establishment, economic struggles, and regional integration.',
              'amDesc': 'የድህረ-ቅኝ ግዛት አስተዳደር፣ የኦኤዩ/አፍሪካ ህብረት ምስረታ፣ ኢኮኖሚያዊ ትግሎች እና ውህደት።',
            },
            {
              'id': 'hist_u8',
              'grade': 12,
              'enUnit': 'Unit 8: Post-1991 Developments in Ethiopia',
              'amUnit': 'ክፍል 8: ከ1991 በኋላ የታዩ እድገቶች በኢትዮጵያ',
              'enDesc': '1991 transition, 1995 FDRE constitution, multinational federalism, and socio-economic transformation.',
              'amDesc': 'የ1983 የሽግግር ወቅት፣ የ1987 የኢፌዴሪ ህገ-መንግስት፣ ፌዴራሊዝም እና ሀገራዊ ማሻሻያዎች።',
            },
            {
              'id': 'hist_u9',
              'grade': 12,
              'enUnit': 'Unit 9: Indigenous Knowledge Systems and Heritages of Ethiopia',
              'amUnit': 'ክፍል 9: የሀገር በቀል እውቀት ስርዓቶች እና የኢትዮጵያ ቅርሶች',
              'enDesc': 'Indigenous knowledge, Gadaa, customary laws, UNESCO tangible and intangible cultural heritages.',
              'amDesc': 'የሀገር በቀል እውቀቶች፣ የገዳ ስርዓት፣ ባህላዊ ህጎች እና የዩኔስኮ ተጨባጭና ኢ-ተጨባጭ ቅርሶች።',
            },
          ];
        }
        return [];

      // ==========================================
      // ECONOMICS
      // ==========================================
      case 'Economics':
        if (grade == 9) {
          return [
            {
              'id': 'econ_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Introducing Economics',
              'amUnit': 'ክፍል 1: የኢኮኖሚክስ መግቢያ',
              'enDesc': 'Definition, nature, micro vs macroeconomics, and economic methodology.',
              'amDesc': 'የኢኮኖሚክስ ምንነት፣ ማይክሮ እና ማክሮ ኢኮኖሚክስ ንጽጽር እና ዘዴዎች።',
            },
            {
              'id': 'econ_u2',
              'grade': 9,
              'enUnit': 'Unit 2: The Basic Economic Problems and Economic Systems',
              'amUnit': 'ክፍል 2: መሰረታዊ የኢኮኖሚ ችግሮች እና የኢኮኖሚ ስርዓቶች',
              'enDesc': 'Scarcity, choice, opportunity cost, PPF, traditional, command, and market economies.',
              'amDesc': 'እጥረት፣ ምርጫ፣ የዕድል ወጪ (Opportunity Cost) እና የኢኮኖሚ ስርዓቶች።',
            },
            {
              'id': 'econ_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Economic Resources and Markets',
              'amUnit': 'ክፍል 3: የኢኮኖሚ ሀብቶች እና ገበያዎች',
              'enDesc': 'Factors of production, circular flow of income, and market structures overview.',
              'amDesc': 'የምርት ሀብቶች፣ የገቢ ዑደት እና የገበያ መዋቅር መሰረታዊ ጽንሰ-ሀሳቦች።',
            },
            {
              'id': 'econ_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Introduction to Demand and Supply',
              'amUnit': 'ክፍል 4: የፍላጎት እና አቅርቦት መግቢያ',
              'enDesc': 'Law of demand, law of supply, demand/supply schedules, and market equilibrium.',
              'amDesc': 'የፍላጎት ህግ፣ የአቅርቦት ህግ እና የገበያ ሚዛን (Equilibrium)።',
            },
            {
              'id': 'econ_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Introduction to Production and Cost',
              'amUnit': 'ክፍል 5: የምርት እና ወጪ መግቢያ',
              'enDesc': 'Production function, short run vs long run, total, average, and marginal costs.',
              'amDesc': 'የምርት ተግባር፣ የአጭርና ረጅም ጊዜ ወጪዎች፣ አማካይ እና ተጨማሪ ወጪ።',
            },
            {
              'id': 'econ_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Introduction to Money',
              'amUnit': 'ክፍል 6: ስለ ገንዘብ መግቢያ',
              'enDesc': 'Barter system, evolution of money, functions of money, and banking services.',
              'amDesc': 'የእቃ በእቃ ልውውጥ፣ የገንዘብ አመጣጥ፣ የገንዘብ ተግባራት እና የባንክ አገልግሎቶች።',
            },
            {
              'id': 'econ_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Introduction to Macroeconomics',
              'amUnit': 'ክፍል 7: የማክሮ ኢኮኖሚክስ መግቢያ',
              'enDesc': 'National income concepts, inflation, unemployment, and fiscal policy basics.',
              'amDesc': 'ብሄራዊ ገቢ፣ የዋጋ ንረት፣ ስራ አጥነት እና የመንግስት የፊስካል ፖሊሲ መሰረቶች።',
            },
            {
              'id': 'econ_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Basic Entrepreneurship',
              'amUnit': 'ክፍል 8: መሰረታዊ የስራ ፈጠራ ክህሎት',
              'enDesc': 'Characteristics of entrepreneurs, business planning, and startup management.',
              'amDesc': 'የስራ ፈጣሪዎች ባህሪያት፣ የንግድ እቅድ ማዘጋጀት እና አዳዲስ ስራዎችን መጀመር።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'econ_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Theory of Consumer Behaviour',
              'amUnit': 'ክፍል 1: የሸማቾች ባህሪ ንድፈ ሃሳብ',
              'enDesc': 'Cardinal and ordinal utility approaches, diminishing marginal utility, and indifference curves.',
              'amDesc': 'ካርዲናል እና ኦርዲናል ረቂቅ እርካታ፣ እየቀነሰ የሚሄድ እርካታ ህግ እና ኢንዲፈረንስ ከርቭ።',
            },
            {
              'id': 'econ_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Theories of Demand and Supply',
              'amUnit': 'ክፍል 2: የፍላጎት እና አቅርቦት ንድፈ ሃሳቦች',
              'enDesc': 'Price elasticity of demand/supply, cross elasticity, and price ceilings/floors.',
              'amDesc': 'የፍላጎትና አቅርቦት የመለጠጥ ባህሪ (Elasticity) እና የዋጋ ቁጥጥሮች።',
            },
            {
              'id': 'econ_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Theories of Production and Cost',
              'amUnit': 'ክፍል 3: የምርት እና የወጪ ንድፈ ሃሳቦች',
              'enDesc': 'Law of diminishing returns, returns to scale, and short-run/long-run cost curves.',
              'amDesc': 'እየቀነሰ የሚሄድ ምርታማነት ህግ እና የወጪ ከርቮች ትንተና።',
            },
            {
              'id': 'econ_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Market Structure',
              'amUnit': 'ክፍል 4: የገበያ መዋቅር',
              'enDesc': 'Perfect competition, monopoly, monopolistic competition, and oligopoly.',
              'amDesc': 'ፍፁም ውድድር፣ ሞኖፖሊ፣ ሞኖፖሊያዊ ውድድር እና ኦሊጎፖሊ የገበያ አይነቶች።',
            },
            {
              'id': 'econ_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Banking and Finance',
              'amUnit': 'ክፍል 5: ባንክ እና ፋይናንስ',
              'enDesc': 'Commercial banks, central bank functions, monetary policy instruments, and fintech.',
              'amDesc': 'የንግድ ባንኮች፣ የማዕከላዊ ባንክ ሚና፣ የገንዘብ ፖሊሲ መሳሪያዎች እና ዲጂታል ፋይናንስ።',
            },
            {
              'id': 'econ_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Economic Growth',
              'amUnit': 'ክፍል 6: የኢኮኖሚ እድገት',
              'enDesc': 'Indicators of economic growth, GDP growth rates, and determinants of sustained growth.',
              'amDesc': 'የኢኮኖሚ እድገት መለኪያዎች፣ የጂዲፒ እድገት ስሌት እና እድገትን የሚያፋጥኑ ሁኔታዎች።',
            },
            {
              'id': 'econ_u7',
              'grade': 10,
              'enUnit': 'Unit 7: The Ethiopian Economy',
              'amUnit': 'ክፍል 7: የኢትዮጵያ ኢኮኖሚ',
              'enDesc': 'Agricultural sector, industrialization, services, foreign trade, and development strategies.',
              'amDesc': 'የግብርና፣ ኢንዱስትሪ እና አገልግሎት ዘርፎች በኢትዮጵያ እና የልማት ፖሊሲዎች።',
            },
            {
              'id': 'econ_u8',
              'grade': 10,
              'enUnit': 'Unit 8: Business Startups and Innovation',
              'amUnit': 'ክፍል 8: የንግድ ጅምር እና ፈጠራ',
              'enDesc': 'Startup ideation, micro-finance access, business marketing, and innovation.',
              'amDesc': 'የንግድ ሃሳብ ማመንጨት፣ የብድር አቅርቦት፣ የገበያ ጥናት እና የፈጠራ ስራዎች።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'econ_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Theory of Consumer Behavior and Demand',
              'amUnit': 'ክፍል 1: የሸማቾች ባህሪ እና ፍላጎት ንድፈ ሃሳብ',
              'enDesc': 'Consumer optimization, indifference map, budget line equations, and demand derivation.',
              'amDesc': 'የሸማቾች ምርጫ ሚዛን፣ ኢንዲፈረንስ ማፕ፣ የበጀት መስመር እኩልታ እና የፍላጎት ግራፍ።',
            },
            {
              'id': 'econ_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Theory of Production and Cost',
              'amUnit': 'ክፍል 2: የአመራረት እና የወጪ ንድፈ ሃሳብ',
              'enDesc': 'Isoquants, isocost lines, optimal input combination, and economies of scale.',
              'amDesc': 'አይሶኳንት፣ አይሶኮስት መስመር፣ አነስተኛ ወጪ የሚያስገኝ የአመራረት ውህደት።',
            },
            {
              'id': 'econ_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Market Structures',
              'amUnit': 'ክፍል 3: የገበያ መዋቅሮች',
              'enDesc': 'Price and output determination under perfect competition, pure monopoly, and oligopoly.',
              'amDesc': 'በፍፁም ውድድር፣ በሞኖፖሊ እና በኦሊጎፖሊ ገበያዎች ውስጥ የዋጋና ምርት መጠን ውሳኔ።',
            },
            {
              'id': 'econ_u4',
              'grade': 11,
              'enUnit': 'Unit 4: National Income Accounting',
              'amUnit': 'ክፍል 4: ብሄራዊ የገቢ ሂሳብ አያያዝ',
              'enDesc': 'GDP, GNP, NNP measurement methods (expenditure, income, product), and real GDP.',
              'amDesc': 'ጂዲፒ፣ ጂኤንፒ፣ ኤንኤንፒን በምርት፣ በገቢ እና በወጪ ዘዴዎች ማስላት እና እውነተኛ ጂዲፒ።',
            },
            {
              'id': 'econ_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Consumption, Saving and Investment',
              'amUnit': 'ክፍል 5: ፍጆታ፣ ቁጠባ እና ኢንቨስትመንት',
              'enDesc': 'Keynesian consumption function, marginal propensity to consume (MPC), and investment multiplier.',
              'amDesc': 'የኬይንሲያን የፍጆታ ተግባር፣ ኤምፒሲ (MPC)፣ ቁጠባ እና የኢንቨስትመንት ማባዣ (Multiplier)።',
            },
            {
              'id': 'econ_u6',
              'grade': 11,
              'enUnit': 'Unit 6: International Trade and Finance',
              'amUnit': 'ክፍል 6: አለም አቀፍ ንግድ እና ፋይናንስ',
              'enDesc': 'Comparative advantage, trade protection, balance of payments, and exchange rates.',
              'amDesc': 'አንጻራዊ ብልጫ፣ የንግድ ታሪፎች፣ የክፍያ ሚዛን (BOP) እና የውጭ ምንዛሬ ተመን።',
            },
            {
              'id': 'econ_u7',
              'grade': 11,
              'enUnit': 'Unit 7: Economic Development and the Ethiopian Economy',
              'amUnit': 'ክፍል 7: የኢኮኖሚ ልማት እና የኢትዮጵያ ኢኮኖሚ',
              'enDesc': 'Growth vs development, Human Development Index (HDI), and Ethiopian development plans.',
              'amDesc': 'እድገት እና ልማት፣ የሰው ልጅ ልማት መረጃ ጠቋሚ (HDI) እና የኢትዮጵያ የልማት እቅዶች።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'econ_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Macroeconomics',
              'amUnit': 'ክፍል 1: ማክሮ ኢኮኖሚክስ',
              'enDesc': 'Macroeconomic scope, aggregate demand and supply, business cycles, and macroeconomic goals.',
              'amDesc': 'የማክሮ ኢኮኖሚክስ ወሰንና ዘዴዎች፣ አጠቃላይ ፍላጎትና አቅርቦት እና የንግድ ዑደቶች።',
            },
            {
              'id': 'econ_u2',
              'grade': 12,
              'enUnit': 'Unit 2: National Income Accounting',
              'amUnit': 'ክፍል 2: ብሄራዊ የገቢ ሂሳብ አያያዝ',
              'enDesc': 'Concepts of GDP, GNP, NNP, measurement approaches, nominal vs real GDP, and price indexes.',
              'amDesc': 'የጂዲፒ፣ ጂኤንፒ፣ ኤንኤንፒ ጽንሰ-ሀሳቦች፣ የመለኪያ ዘዴዎች እና ኖሚናልና እውነተኛ ጂዲፒ።',
            },
            {
              'id': 'econ_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Money and Banking',
              'amUnit': 'ክፍል 3: ገንዘብ እና የባንክ አገልግሎት',
              'enDesc': 'Evolution and functions of money, money supply measures, commercial banking and central bank.',
              'amDesc': 'የገንዘብ አመጣጥና ተግባራት፣ የገንዘብ አቅርቦት መለኪያዎች፣ የንግድ ባንኮች እና ማዕከላዊ ባንክ።',
            },
            {
              'id': 'econ_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Inflation and Unemployment',
              'amUnit': 'ክፍል 4: የዋጋ ንረት እና ስራ አጥነት',
              'enDesc': 'Causes and consequences of inflation, types of unemployment, Okun’s law, and Phillips curve.',
              'amDesc': 'የዋጋ ንረት መንስኤዎችና መዘዞች፣ የስራ አጥነት አይነቶች፣ የኦኩን ህግ እና የፊሊፕስ ከርቭ።',
            },
            {
              'id': 'econ_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Fiscal and Monetary Policy',
              'amUnit': 'ክፍል 5: የፊስካል እና የገንዘብ ፖሊሲ',
              'enDesc': 'Government budget, taxation types, fiscal policy tools, and monetary policy instruments.',
              'amDesc': 'የመንግስት በጀት፣ የታክስ አይነቶች፣ የፊስካል ፖሊሲ መሳሪያዎች እና የገንዘብ ፖሊሲ ስልቶች።',
            },
            {
              'id': 'econ_u6',
              'grade': 12,
              'enUnit': 'Unit 6: International Trade',
              'amUnit': 'ክፍል 6: አለም አቀፍ ንግድ',
              'enDesc': 'Absolute and comparative advantage, gains from trade, trade protectionism, and exchange rates.',
              'amDesc': 'ፍፁም እና አንጻራዊ ብልጫ፣ የንግድ ጥቅሞች፣ የንግድ ጥበቃ (ታሪፍ፣ ኮታ) እና የምንዛሬ ተመን።',
            },
            {
              'id': 'econ_u7',
              'grade': 12,
              'enUnit': 'Unit 7: Economic Development',
              'amUnit': 'ክፍል 7: የኢኮኖሚ ልማት',
              'enDesc': 'Growth vs development, human development index (HDI), poverty alleviation, and SDGs.',
              'amDesc': 'እድገት እና ልማት፣ የሰው ልጅ ልማት መረጃ ጠቋሚ (HDI)፣ የድህነት ቅነሳ ስልቶች እና ዘላቂ ግቦች።',
            },
            {
              'id': 'econ_u8',
              'grade': 12,
              'enUnit': 'Unit 8: Ethiopian Economy',
              'amUnit': 'ክፍል 8: የኢትዮጵያ ኢኮኖሚ',
              'enDesc': 'Structure of Ethiopian economy, agriculture, industry, services, macroeconomic reforms.',
              'amDesc': 'የኢትዮጵያ ኢኮኖሚ መዋቅር፣ ግብርና፣ ኢንዱስትሪ፣ የአገልግሎት ዘርፍ እና የማክሮ ኢኮኖሚ ማሻሻያዎች።',
            },
          ];
        }
        return [];

      // ==========================================
      // GEOGRAPHY
      // ==========================================
      case 'Geography':
        if (grade == 9) {
          return [
            {
              'id': 'geo_u1',
              'grade': 9,
              'enUnit': 'Unit 1: Geological History and Topography of Ethiopia',
              'amUnit': 'ክፍል 1: የኢትዮጵያ ጂኦሎጂካል ታሪክ እና የመሬት አቀማመጥ',
              'enDesc': 'Geological eras, rock formation, physiographic divisions of Ethiopia, and landforms.',
              'amDesc': 'የኢትዮጵያ ጂኦሎጂካል ታሪክ፣ የአለቶች አፈጣጠር፣ የመሬት አቀማመጥ ክፍሎች እና ተራሮች።',
            },
            {
              'id': 'geo_u2',
              'grade': 9,
              'enUnit': 'Unit 2: Climate of Ethiopia',
              'amUnit': 'ክፍል 2: የኢትዮጵያ አየር ንብረት',
              'enDesc': 'Controls of weather and climate in Ethiopia, traditional agro-climatic zones, and rainfall.',
              'amDesc': 'የኢትዮጵያን የአየር ንብረት የሚቆጣጠሩ ሁኔታዎች፣ ባህላዊ የአየር ንብረት ቀጠናዎች እና ዝናብ።',
            },
            {
              'id': 'geo_u3',
              'grade': 9,
              'enUnit': 'Unit 3: Natural Resource Base of Ethiopia',
              'amUnit': 'ክፍል 3: የኢትዮጵያ የተፈጥሮ ሀብት መሰረት',
              'enDesc': 'Drainage basins, river systems, lakes, soils, natural vegetation, and wildlife in Ethiopia.',
              'amDesc': 'የኢትዮጵያ ወንዞች፣ ሐይቆች፣ የአፈር አይነቶች፣ የተፈጥሮ ደኖች እና የዱር እንስሳት።',
            },
            {
              'id': 'geo_u4',
              'grade': 9,
              'enUnit': 'Unit 4: Population and Demographic Characteristics of Ethiopia',
              'amUnit': 'ክፍል 4: የኢትዮጵያ ህዝብ እና የስነ-ህዝብ ባህሪያት',
              'enDesc': 'Population size, growth rates, spatial distribution, demographic structure, and migration.',
              'amDesc': 'የህዝብ ብዛት፣ የእድገት ፍጥነት፣ የስርጭት ሁኔታ፣ የስነ-ህዝብ መዋቅር እና ፍልሰት።',
            },
            {
              'id': 'geo_u5',
              'grade': 9,
              'enUnit': 'Unit 5: Major Economic and Cultural Activities in Ethiopia',
              'amUnit': 'ክፍል 5: ዋና ዋና የኢኮኖሚ እና ባህላዊ እንቅስቃሴዎች በኢትዮጵያ',
              'enDesc': 'Agriculture, manufacturing industry, transport, communication, and tourism in Ethiopia.',
              'amDesc': 'ግብርና፣ አምራች ኢንዱስትሪ፣ ትራንስፖርት፣ ኮሙኒኬሽን እና ቱሪዝም በኢትዮጵያ።',
            },
            {
              'id': 'geo_u6',
              'grade': 9,
              'enUnit': 'Unit 6: Human–Natural Environment Interactions in Ethiopia',
              'amUnit': 'ክፍል 6: የሰው እና የተፈጥሮ አካባቢ መስተጋብር በኢትዮጵያ',
              'enDesc': 'Deforestation, soil erosion, land degradation, water management, and conservation.',
              'amDesc': 'የደን መጨፍጨፍ፣ የአፈር መሸርሸር፣ የመሬት መራቆት እና የተፈጥሮ ሀብት ጥበቃ።',
            },
            {
              'id': 'geo_u7',
              'grade': 9,
              'enUnit': 'Unit 7: Contemporary Geographic Issues and Public Concerns in Ethiopia',
              'amUnit': 'ክፍል 7: ወቅታዊ የጂኦግራፊያዊ ጉዳዮች እና የህዝብ ስጋቶች በኢትዮጵያ',
              'enDesc': 'Rapid urbanization, food insecurity, climate change impacts, and natural disasters.',
              'amDesc': 'ፈጣን የከተሞች መስፋፋት፣ የምግብ ዋስትና፣ የአየር ንብረት ለውጥ እና የተፈጥሮ አደጋዎች።',
            },
            {
              'id': 'geo_u8',
              'grade': 9,
              'enUnit': 'Unit 8: Geographic Inquiry Skills and Techniques',
              'amUnit': 'ክፍል 8: የጂኦግራፊያዊ ምርመራ ክህሎቶች እና ቴክኒኮች',
              'enDesc': 'Map reading skills, scales, grid references, relief representation, and field surveys.',
              'amDesc': 'የካርታ ንባብ ክህሎቶች፣ የካርታ ልኬቶች፣ የግሪድ መረጃዎች እና የመስክ ጥናት።',
            },
          ];
        }
        if (grade == 10) {
          return [
            {
              'id': 'geo_u1',
              'grade': 10,
              'enUnit': 'Unit 1: Landforms of Africa',
              'amUnit': 'ክፍል 1: የአፍሪካ የመሬት ገጽታዎች',
              'enDesc': 'Geological structure of Africa, plateaus, East African rift valley, mountains, and basins.',
              'amDesc': 'የአፍሪካ ጂኦሎጂካል አወቃቀር፣ አምባዎች፣ የምስራቅ አፍሪካ ስምጥ ሸለቆ እና ተራሮች።',
            },
            {
              'id': 'geo_u2',
              'grade': 10,
              'enUnit': 'Unit 2: Climate of Africa',
              'amUnit': 'ክፍል 2: የአፍሪካ አየር ንብረት',
              'enDesc': 'Factors affecting African climate, ITCZ, planetary winds, and climatic classification.',
              'amDesc': 'የአፍሪካን አየር ንብረት የሚወስኑ ሁኔታዎች፣ አይቲሲዜድ (ITCZ) እና የአየር ንብረት ቀጠናዎች።',
            },
            {
              'id': 'geo_u3',
              'grade': 10,
              'enUnit': 'Unit 3: Natural Resource Base of Africa',
              'amUnit': 'ክፍል 3: የአፍሪካ የተፈጥሮ ሀብት መሰረት',
              'enDesc': 'Major river systems, lakes, soils, mineral wealth, tropical forests, and wildlife.',
              'amDesc': 'ዋና ዋና የአፍሪካ ወንዞች፣ ሐይቆች፣ የአፈር አይነቶች፣ የማዕድን ሀብቶች እና ደኖች።',
            },
            {
              'id': 'geo_u4',
              'grade': 10,
              'enUnit': 'Unit 4: Population of Africa',
              'amUnit': 'ክፍል 4: የአፍሪካ ህዝብ ብዛት',
              'enDesc': 'Population dynamics, fertility, mortality, urbanization, and migration trends across Africa.',
              'amDesc': 'የህዝብ ብዛት ተለዋዋጭነት፣ የውልደትና ሞት መጠን፣ የከተሞች እድገት እና ፍልሰት በአፍሪካ።',
            },
            {
              'id': 'geo_u5',
              'grade': 10,
              'enUnit': 'Unit 5: Major Economic and Cultural Activities of Africa',
              'amUnit': 'ክፍል 5: የአፍሪካ ዋና ዋና የኢኮኖሚ እና ባህላዊ እንቅስቃሴዎች',
              'enDesc': 'African agriculture systems, mining, manufacturing sector, trade, and cultural heritage.',
              'amDesc': 'የግብርና ስርዓቶች፣ ማዕድን ማውጣት፣ የማኑፋክቸሪንግ ዘርፍ፣ ንግድ እና ባህላዊ ቅርሶች።',
            },
            {
              'id': 'geo_u6',
              'grade': 10,
              'enUnit': 'Unit 6: Human–Natural Environment Interactions',
              'amUnit': 'ክፍል 6: የሰው እና የተፈጥሮ አካባቢ መስተጋብር',
              'enDesc': 'Environmental degradation, desertification, drought, famine, and environmental management.',
              'amDesc': 'የአካባቢ መራቆት፣ የበረሃማነት መስፋፋት፣ ድርቅ፣ ረሃብ እና የአካባቢ ጥበቃ እርምጃዎች።',
            },
            {
              'id': 'geo_u7',
              'grade': 10,
              'enUnit': 'Unit 7: Geographic Issues and Public Concerns in Africa',
              'amUnit': 'ክፍል 7: ጂኦግራፊያዊ ጉዳዮች እና የህዝብ ስጋቶች በአፍሪካ',
              'enDesc': 'Climate vulnerability, refugee crises, cross-border resource conflicts, and development.',
              'amDesc': 'የአየር ንብረት ተጋላጭነት፣ የስደተኞች ቀውስ፣ የድንበር ተሻጋሪ ሀብቶች ግጭት እና ልማት።',
            },
            {
              'id': 'geo_u8',
              'grade': 10,
              'enUnit': 'Unit 8: Geospatial Information and Data Processing',
              'amUnit': 'ክፍል 8: የጂኦስፓሻል መረጃ እና የዳታ ማቀነባበሪያ',
              'enDesc': 'Remote sensing fundamentals, GPS positioning, GIS data structures, and digital mapping.',
              'amDesc': 'የርቀት ዳሰሳ (Remote Sensing)፣ ጂፒኤስ (GPS)፣ የጂአይኤስ ዳታ አወቃቀር እና ዲጂታል ካርታ።',
            },
          ];
        }
        if (grade == 11) {
          return [
            {
              'id': 'geo_u1',
              'grade': 11,
              'enUnit': 'Unit 1: Formation of the Continents',
              'amUnit': 'ክፍል 1: የአህጉራት አፈጣጠር',
              'enDesc': 'Continental drift theory, plate tectonics, sea-floor spreading, and major landforms creation.',
              'amDesc': 'የአህጉራት መንሸራተት ንድፈ-ሀሳብ፣ ፕሌት ቴክቶኒክስ እና የመሬት ገጽታዎች አፈጣጠር።',
            },
            {
              'id': 'geo_u2',
              'grade': 11,
              'enUnit': 'Unit 2: Climate Classification and Climate Regions of Our World',
              'amUnit': 'ክፍል 2: የአየር ንብረት ምደባ እና የአለማችን የአየር ንብረት ቀጠናዎች',
              'enDesc': 'Köppen climate classification, global wind circulation, temperature zones, and world biomes.',
              'amDesc': 'የኮፐን የአየር ንብረት ምደባ፣ የአለም አቀፍ የንፋስ ዝውውር እና የአለማችን ባዮሞች።',
            },
            {
              'id': 'geo_u3',
              'grade': 11,
              'enUnit': 'Unit 3: Natural Resources and Conflicts Over Resources',
              'amUnit': 'ክፍል 3: የተፈጥሮ ሀብቶች እና በሀብቶች ላይ የሚነሱ ግጭቶች',
              'enDesc': 'Water politics, transboundary rivers, fossil fuels, mineral competition, and geopolitical conflicts.',
              'amDesc': 'የውሃ ፖለቲካ፣ ድንበር ተሻጋሪ ወንዞች፣ የነዳጅ እና ማዕድናት ውድድርና ግጭቶች።',
            },
            {
              'id': 'geo_u4',
              'grade': 11,
              'enUnit': 'Unit 4: Global Population Dynamics and Challenges',
              'amUnit': 'ክፍል 4: የአለም ህዝብ ብዛት ተለዋዋጭነት እና ተግዳሮቶች',
              'enDesc': 'World population trends, aging vs youthful populations, megacities, and global migration.',
              'amDesc': 'የአለም ህዝብ ቁጥር አዝማሚያ፣ የእርጅና እና የወጣት ህዝብ ስብጥር፣ እና ሜጋ-ከተሞች።',
            },
            {
              'id': 'geo_u5',
              'grade': 11,
              'enUnit': 'Unit 5: Economic Development and Global Inequality',
              'amUnit': 'ክፍል 5: የኢኮኖሚ ልማት እና የአለም አቀፍ እኩልነት ማጣት',
              'enDesc': 'Core-periphery model, North-South economic divide, global trade patterns, and globalization.',
              'amDesc': 'የሰሜንና ደቡብ የኢኮኖሚ ክፍፍል፣ የአለም ንግድ አሰራር እና ግሎባላይዜሽን።',
            },
            {
              'id': 'geo_u6',
              'grade': 11,
              'enUnit': 'Unit 6: Environmental Changes and Management',
              'amUnit': 'ክፍል 6: የአካባቢ ለውጦች እና አስተዳደር',
              'enDesc': 'Biodiversity loss, ozone depletion, global warming, sustainable conservation, and treaties.',
              'amDesc': 'የብዝሃ ህይወት መጥፋት፣ የኦዞን መመናመን፣ የአለም ሙቀት መጨመር እና የአካባቢ ስምምነቶች።',
            },
            {
              'id': 'geo_u7',
              'grade': 11,
              'enUnit': 'Unit 7: Geographic Information System',
              'amUnit': 'ክፍል 7: የጂኦግራፊያዊ መረጃ ስርዓት (GIS)',
              'enDesc': 'GIS architecture, spatial and attribute data, coordinate systems, map overlaying, and queries.',
              'amDesc': 'የጂአይኤስ አወቃቀር፣ የቦታ እና የባህሪ ዳታ፣ የመጋጠሚያ ስርዓቶች እና የካርታ ንብርብሮች።',
            },
            {
              'id': 'geo_u8',
              'grade': 11,
              'enUnit': 'Unit 8: Geographic Issues and Public Concerns',
              'amUnit': 'ክፍል 8: ጂኦግራፊያዊ ጉዳዮች እና የህዝብ ስጋቶች',
              'enDesc': 'Environmental pollution, disease spread geography, disaster risk reduction, and green energy.',
              'amDesc': 'የአካባቢ ብክለት፣ የበሽታዎች ስርጭት ጂኦግራፊ፣ የተፈጥሮ አደጋ ቅነሳ እና አረንጓዴ ሃይል።',
            },
          ];
        }
        if (grade == 12) {
          return [
            {
              'id': 'geo_u1',
              'grade': 12,
              'enUnit': 'Unit 1: Major Geological Processes Associated with Plate Tectonics',
              'amUnit': 'ክፍል 1: ከፕሌት ቴክቶኒክስ ጋር የተያያዙ ዋና ዋና ጂኦሎጂካዊ ሂደቶች',
              'enDesc': 'Plate boundaries, faulting, folding, volcanism, earthquakes, and seismic hazard mitigation.',
              'amDesc': 'የፕሌት ድንበሮች፣ ስብራት፣ እጥፋት፣ እሳተ ገሞራ፣ የመሬት መንቀጥቀጥ እና የአደጋ ቅነሳ።',
            },
            {
              'id': 'geo_u2',
              'grade': 12,
              'enUnit': 'Unit 2: Climate Change',
              'amUnit': 'ክፍል 2: የአየር ንብረት ለውጥ',
              'enDesc': 'Causes of global climate change, greenhouse effect, extreme weather events, and agreements.',
              'amDesc': 'የአለም አየር ንብረት ለውጥ መንስኤዎች፣ የግሪንሃውስ ተፅዕኖ እና አለም አቀፍ ስምምነቶች።',
            },
            {
              'id': 'geo_u3',
              'grade': 12,
              'enUnit': 'Unit 3: Management of Conflict Over Resources',
              'amUnit': 'ክፍል 3: በሀብቶች ላይ የሚነሱ ግጭቶች አያያዝ',
              'enDesc': 'Resource scarcity, international water treaties, Nile basin management, and peaceful dispute resolution.',
              'amDesc': 'የሀብት እጥረት፣ አለም አቀፍ የውሃ ስምምነቶች፣ የአባይ ተፋሰስ አስተዳደር እና የግጭት አፈታት።',
            },
            {
              'id': 'geo_u4',
              'grade': 12,
              'enUnit': 'Unit 4: Population Policies, Programs and the Environment',
              'amUnit': 'ክፍል 4: የህዝብ ፖሊሲዎች፣ ፕሮግራሞች እና አካባቢ',
              'enDesc': 'Population control policies, reproductive health, environmental carrying capacity, and planning.',
              'amDesc': 'የህዝብ ፖሊሲዎች፣ የስነ-ተዋልዶ ጤና፣ የአካባቢ የመሸከም አቅም እና ዘላቂ እቅድ።',
            },
            {
              'id': 'geo_u5',
              'grade': 12,
              'enUnit': 'Unit 5: Economic Development and Global Inequality',
              'amUnit': 'ክፍል 5: የኢኮኖሚ ልማት እና የአለም አቀፍ እኩልነት ማጣት',
              'enDesc': 'Spatial disparities, globalization consequences, technological divide, and regional economic unions.',
              'amDesc': 'የቦታ ልማት ልዩነቶች፣ የግ堅持ባላይዜሽን መዘዞች፣ የቴክኖሎጂ ልዩነት እና ቀጠናዊ ህብረቶች።',
            },
            {
              'id': 'geo_u6',
              'grade': 12,
              'enUnit': 'Unit 6: Environmental Management',
              'amUnit': 'ክፍል 6: የአካባቢ ጥበቃ እና አስተዳደር',
              'enDesc': 'Environmental impact assessment (EIA), biodiversity conservation, and ecosystem restoration.',
              'amDesc': 'የአካባቢ ተፅዕኖ ግምገማ (EIA)፣ የብዝሃ ህይወት ጥበቃ እና የስነ-ምህዳር መልሶ ማቋቋም።',
            },
            {
              'id': 'geo_u7',
              'grade': 12,
              'enUnit': 'Unit 7: Geospatial Technologies',
              'amUnit': 'ክፍል 7: የጂኦስፓሻል ቴክኖሎጂዎች',
              'enDesc': 'Advanced GIS analysis, satellite remote sensing, photogrammetry, GPS, and spatial modeling.',
              'amDesc': 'የላቀ የጂአይኤስ ትንተና፣ የሳተላይት የርቀት ዳሰሳ፣ ፎቶግራሜትሪ፣ ጂፒኤስ እና የቦታ ሞዴሊንግ።',
            },
            {
              'id': 'geo_u8',
              'grade': 12,
              'enUnit': 'Unit 8: Contemporary Geographic Issues and Public Concerns',
              'amUnit': 'ክፍል 8: ወቅታዊ የጂኦግራፊያዊ ጉዳዮች እና የህዝብ ስጋቶች',
              'enDesc': 'Urban sprawl, global waste management, food security challenges, and environmental resilience.',
              'amDesc': 'የከተሞች መስፋፋት፣ የቆሻሻ አያያዝ፣ የምግብ ዋስትና ፈተናዎች እና የአካባቢ ጥንካሬ።',
            },
          ];
        }
        return [];

      default:
        return [];
    }
  }
}
