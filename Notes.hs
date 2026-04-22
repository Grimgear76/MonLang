module Main where

-- ═══════════════════════════════════════════════════════════════════════════
--  NOTES.HS — MonLang Explained Line by Line
--  This file is a copy of Main.hs with detailed explanations of every part.
--  Use this to study for Q&A. The actual runnable code is in Main.hs.
-- ═══════════════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────────────
--  WHAT IS MONLANG?
-- ───────────────────────────────────────────────────────────────────────────
--  MonLang is a small domain-specific language (DSL) inspired by Pokémon.
--  It is NOT a general-purpose language — it only knows how to:
--    1. Declare monsters (like defining a Pokémon)
--    2. Declare moves (like defining an attack)
--    3. Print a monster's info
--    4. Apply a move (show what it would do)
--    5. Run a 1v1 turn-based battle between two monsters
--
--  The language is implemented as an AST (Abstract Syntax Tree) in Haskell.
--  There is no parser — programs are written directly as Haskell values.
--  The evaluator walks the AST and performs actions (printing, battling).


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 1: CONTEXT-FREE GRAMMAR (CFG)
-- ═══════════════════════════════════════════════════════════════════════════
--
--  A CFG formally defines the syntax of a language using rules.
--  Each rule says: "this non-terminal can be replaced by this sequence."
--  Non-terminals are in <angle brackets>. Terminals are "quoted strings".
--
--  IMPORTANT: Every CFG rule below has a matching Haskell data type or
--  constructor. That is what "CFG ↔ AST consistency" means.
--
--  AST: data Program = Program [Stmt]
--   <program>       ::= <stmt-list>
--        A program is just a list of statements.
--
--   <stmt-list>     ::= <stmt>
--                     | <stmt> <stmt-list>
--        A statement list is one statement, or a statement followed by more.
--        This is a recursive rule — it handles any number of statements.
--
--  AST: data Stmt = DeclStmt Decl | PrintStmt MonsterName
--                 | Apply MonsterName MoveName
--                 | Battle MonsterName MonsterName
--   <stmt>          ::= <decl>
--                     | <print-stmt>
--                     | <apply-stmt>
--                     | <battle-stmt>
--        A statement is one of four things. Each maps to an AST constructor.
--
--  ── Declarations ───────────────────────────────────────────────────────────
--
--  AST: data Decl = MonsterDecl ... | MoveDecl ...
--   <decl>          ::= <monster-decl>
--                     | <move-decl>
--
--  AST: MonsterDecl MonsterName Type Stats Ability [MoveName]
--   <monster-decl>  ::= "monster" <mon-id> "{" <monster-body> "}"
--        Concrete example:  monster Pikachu { ... }
--
--   <monster-body>  ::= "type"    <type>
--                       "stats"   "{" <stat-list> "}"
--                       "ability" <ability>
--                       "moves"   "[" <move-id-list> "]"
--        The body has four fixed fields in order: type, stats, ability, moves.
--        Each field maps to a field in MonsterDecl.
--
--  AST: data Stats = Stats Int Int Int Int  (hp atk def spd)
--   <stat-list>     ::= <stat>
--                     | <stat> <stat-list>
--
--   <stat>          ::= "hp"      <num>
--                     | "attack"  <num>
--                     | "defense" <num>
--                     | "speed"   <num>
--        The four integers in Stats correspond to these four fields.
--
--  AST: MoveDecl MoveName Int Int Type  (name power accuracy type)
--   <move-decl>     ::= "move" <move-id> "{" <move-body> "}"
--        Concrete example:  move Thunderbolt { ... }
--
--   <move-body>     ::= "power"    <num>
--                       "accuracy" <num>
--                       "type"     <type>
--        Three fields: power (how strong), accuracy (how likely to hit), type.
--
--  ── Statements ─────────────────────────────────────────────────────────────
--
--  AST: PrintStmt MonsterName
--   <print-stmt>    ::= "print" <mon-id>
--        Prints a monster's full info. Uses <mon-id>, not <move-id>.
--
--  AST: Apply MonsterName MoveName
--   <apply-stmt>    ::= "apply" <mon-id> <move-id>
--        Shows what happens when a monster uses a move (no battle damage).
--        First argument is a monster, second is a move — different namespaces.
--
--  AST: Battle MonsterName MonsterName
--   <battle-stmt>   ::= "battle" <mon-id> <mon-id>
--        Runs a full 1v1 turn-based battle between two monsters.
--        Both arguments are monster names.
--
--  ── Shared Non-Terminals ───────────────────────────────────────────────────
--
--  AST: data Type = Fire | Water | Electric | Grass | Normal
--   <type>          ::= "Fire" | "Water" | "Electric"
--                     | "Grass" | "Normal"
--        Exactly 5 options, matching the 5 constructors of the Type data type.
--
--  AST: type Ability = String
--   <ability>       ::= <mon-id>
--        An ability is just a name (e.g., "Static", "Blaze").
--
--  AST: type MonsterName = String   (monster namespace)
--   <mon-id>        ::= letter (letter | digit)*
--        Identifiers for monsters: start with a letter, then letters or digits.
--        Examples: Pikachu, Charmander, M2
--
--  AST: type MoveName = String      (move namespace)
--   <move-id>       ::= letter (letter | digit)*
--        Same syntactic form as <mon-id>, but a DIFFERENT namespace.
--        "Thunderbolt" is a <move-id>; "Pikachu" is a <mon-id>.
--        Keeping them separate prevents using a monster name where a move
--        name is expected and vice versa.
--
--   <move-id-list>  ::= <move-id>
--                     | <move-id> "," <move-id-list>
--
--   <num>           ::= digit+
--        One or more digits. Used for HP, ATK, DEF, SPD, power, accuracy.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 2: TYPE ALIASES
-- ═══════════════════════════════════════════════════════════════════════════

type MonsterName = String
type MoveName    = String
type Ability     = String

-- EXPLANATION:
--  `type` in Haskell creates a TYPE ALIAS — a new name for an existing type.
--  MonsterName, MoveName, and Ability are all just Strings underneath.
--
--  WHY USE THEM?
--  They make function signatures self-documenting.
--  Compare:
--    evalStmts :: [Stmt] -> ([(String,Monster)], [(String,Move)]) -> IO ()
--  vs:
--    evalStmts :: [Stmt] -> Env -> IO ()
--
--  The second is much clearer. The alias doesn't add type safety — Haskell
--  treats MonsterName and String as identical — but it documents intent.
--
--  CFG CONNECTION:
--    MonsterName  ↔  <mon-id>
--    MoveName     ↔  <move-id>
--    Ability      ↔  <ability>


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 3: ELEMENT TYPES (the Type data type)
-- ═══════════════════════════════════════════════════════════════════════════

data Type = Fire | Water | Electric | Grass | Normal
  deriving Eq

-- EXPLANATION:
--  This is an ALGEBRAIC DATA TYPE (ADT) — specifically a SUM TYPE.
--  A sum type means a value is exactly ONE of the listed options.
--  Fire, Water, Electric, Grass, Normal are called DATA CONSTRUCTORS.
--  They take no arguments — they are like named constants.
--
--  `deriving Eq` automatically generates an equality check (==) so we can
--  compare types: Fire == Fire is True, Fire == Water is False.
--  We need Eq for typeEffectiveness pattern matching.
--
--  WHY NOT `deriving Show`?
--  The rubric requires CUSTOM Show instances. With `deriving Show`, Haskell
--  would print "Fire" as "Fire" anyway, but we write it ourselves to prove
--  we control the output format.
--
--  CFG CONNECTION:
--    <type> ::= "Fire" | "Water" | "Electric" | "Grass" | "Normal"
--    Each constructor corresponds to one terminal in the CFG.

instance Show Type where
  show Fire     = "Fire"
  show Water    = "Water"
  show Electric = "Electric"
  show Grass    = "Grass"
  show Normal   = "Normal"

-- EXPLANATION:
--  `instance Show Type` means we are implementing the Show TYPE CLASS for Type.
--  A type class is like an interface — Show requires a `show` function that
--  converts a value to a String.
--
--  Pattern matching: each line matches one constructor and returns its string.
--  This is exhaustive — all 5 constructors are covered, so GHC won't warn.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 4: STATS
-- ═══════════════════════════════════════════════════════════════════════════

data Stats = Stats Int Int Int Int   -- hp attack defense speed

-- EXPLANATION:
--  Stats is a PRODUCT TYPE — it holds multiple values at once (like a struct).
--  `Stats Int Int Int Int` means: the Stats constructor takes four Ints.
--  The order is: hp, attack, defense, speed (documented in the comment).
--
--  Example: Stats 35 55 40 90 means HP=35, ATK=55, DEF=40, SPD=90
--
--  CFG CONNECTION:
--    <stat-list> ::= "hp" <num> "attack" <num> "defense" <num> "speed" <num>
--    The four <num> values become the four Ints in Stats.

instance Show Stats where
  show (Stats h a d s) =
    "HP "  ++ show h ++ " / ATK " ++ show a ++
    " / DEF " ++ show d ++ " / SPD " ++ show s

-- EXPLANATION:
--  Pattern matching destructures the Stats value: h=hp, a=atk, d=def, s=spd.
--  `show h` converts the Int h to a String (e.g., 35 → "35").
--  `++` is the string concatenation operator in Haskell.
--  Output example: "HP 35 / ATK 55 / DEF 40 / SPD 90"


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 5: AST — DECLARATIONS (Decl)
-- ═══════════════════════════════════════════════════════════════════════════

data Decl
  = MonsterDecl MonsterName Type Stats Ability [MoveName]
  | MoveDecl    MoveName Int Int Type   -- name power accuracy type

-- EXPLANATION:
--  Decl is a SUM TYPE with two constructors — a declaration is either a
--  MonsterDecl or a MoveDecl.
--
--  MonsterDecl holds: name, element type, stats, ability name, list of moves
--  MoveDecl holds:    name, power (Int), accuracy (Int), element type
--
--  [MoveName] is a Haskell LIST of MoveName strings. Square brackets mean list.
--
--  CFG CONNECTION:
--    <decl>         ::= <monster-decl> | <move-decl>
--    <monster-decl> ::= "monster" <mon-id> "{" <monster-body> "}"
--      maps to → MonsterDecl MonsterName Type Stats Ability [MoveName]
--    <move-decl>    ::= "move" <move-id> "{" <move-body> "}"
--      maps to → MoveDecl MoveName Int Int Type
--
--  The constructors ARE the AST nodes. Writing:
--    MonsterDecl "Pikachu" Electric (Stats 35 55 40 90) "Static" ["Thunderbolt"]
--  is how you write a MonLang monster declaration in Haskell.

instance Show Decl where
  show (MonsterDecl name t stats ab moves) =
    "monster " ++ name ++
    " { type " ++ show t ++
    ", stats { " ++ show stats ++ " }" ++
    ", ability " ++ ab ++
    ", moves [" ++ showNames moves ++ "] }"
  show (MoveDecl name pow acc t) =
    "move " ++ name ++
    " { power " ++ show pow ++
    ", accuracy " ++ show acc ++
    ", type " ++ show t ++ " }"

-- EXPLANATION:
--  Two pattern-match cases, one for each constructor.
--  For MonsterDecl: destructures all 5 fields and formats them.
--    `show t` calls Show Type, giving "Electric" etc.
--    `show stats` calls Show Stats, giving "HP 35 / ATK 55 / DEF 40 / SPD 90"
--    `showNames moves` is our helper (defined below) for comma-separated lists.
--  For MoveDecl: destructures 4 fields and formats them.
--    `show pow` and `show acc` convert Ints to Strings.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 6: AST — STATEMENTS (Stmt)
-- ═══════════════════════════════════════════════════════════════════════════

data Stmt
  = DeclStmt  Decl
  | PrintStmt MonsterName
  | Apply     MonsterName MoveName
  | Battle    MonsterName MonsterName

-- EXPLANATION:
--  Stmt is a SUM TYPE with 4 constructors — the 4 things you can say in MonLang.
--
--  DeclStmt wraps a Decl (either MonsterDecl or MoveDecl).
--    This is how declarations appear inside a Program's statement list.
--
--  PrintStmt takes one MonsterName — the name of the monster to display.
--
--  Apply takes a MonsterName and a MoveName — "monster uses move".
--    Note the types are different: MonsterName ≠ MoveName (separate namespaces).
--
--  Battle takes two MonsterNames — "fight these two monsters".
--    Both are in the monster namespace, not the move namespace.
--
--  CFG CONNECTION:
--    <stmt> ::= <decl> | <print-stmt> | <apply-stmt> | <battle-stmt>
--    DeclStmt  ↔  <decl>
--    PrintStmt ↔  <print-stmt>   ::= "print" <mon-id>
--    Apply     ↔  <apply-stmt>   ::= "apply" <mon-id> <move-id>
--    Battle    ↔  <battle-stmt>  ::= "battle" <mon-id> <mon-id>

instance Show Stmt where
  show (DeclStmt d)    = show d
  show (PrintStmt n)   = "print " ++ n
  show (Apply mn mv)   = "apply " ++ mn ++ " " ++ mv
  show (Battle n1 n2)  = "battle " ++ n1 ++ " " ++ n2

-- EXPLANATION:
--  DeclStmt just delegates to Show Decl (calls show on the wrapped Decl).
--  The others format their arguments with the keyword in front.
--  These produce the "concrete syntax" representation of each statement.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 7: AST — PROGRAM
-- ═══════════════════════════════════════════════════════════════════════════

data Program = Program [Stmt]

-- EXPLANATION:
--  Program is a PRODUCT TYPE with one constructor that holds a list of Stmts.
--  [Stmt] means "a list of Stmt values".
--  A program in MonLang is simply an ordered sequence of statements.
--
--  CFG CONNECTION:
--    <program> ::= <stmt-list>
--    Program [Stmt] directly represents the flattened <stmt-list>.

instance Show Program where
  show (Program stmts) = unlines (map show stmts)

-- EXPLANATION:
--  `map show stmts` applies `show` to every Stmt in the list, giving [String].
--  `unlines` joins a [String] into one String with newlines between each.
--    unlines ["a","b","c"]  →  "a\nb\nc\n"
--  So showing a Program prints each statement on its own line.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 8: RUNTIME VALUES (Monster and Move)
-- ═══════════════════════════════════════════════════════════════════════════
--
--  IMPORTANT DISTINCTION:
--  Decl = AST node (part of the program text, what you write)
--  Monster/Move = runtime value (what the evaluator creates and stores)
--
--  When the evaluator sees a MonsterDecl, it constructs a Monster and stores
--  it in the environment. They have the same fields, but serve different roles.

data Monster = Monster MonsterName Type Stats Ability [MoveName]

instance Show Monster where
  show (Monster name t stats ab moves) =
    "[ " ++ name ++ " ]\n" ++
    "  Type    : " ++ show t     ++ "\n" ++
    "  Stats   : " ++ show stats ++ "\n" ++
    "  Ability : " ++ ab         ++ "\n" ++
    "  Moves   : " ++ showNames moves

-- EXPLANATION:
--  The custom Show for Monster produces a multi-line, human-readable card.
--  `\n` is the newline character inside a Haskell string.
--  The fields are vertically aligned using spaces for readability.
--  This is what gets printed when you write `print Pikachu` in MonLang.
--
--  Sample output:
--    [ Pikachu ]
--      Type    : Electric
--      Stats   : HP 35 / ATK 55 / DEF 40 / SPD 90
--      Ability : Static
--      Moves   : Thunderbolt, QuickAttack

data Move = Move MoveName Int Int Type

instance Show Move where
  show (Move name pow acc t) =
    name ++ " (" ++ show t ++
    " | Power: " ++ show pow ++
    " | Accuracy: " ++ show acc ++ "%)"

-- EXPLANATION:
--  Move stores: name, power (Int), accuracy (Int), type.
--  Show formats it as:  Thunderbolt (Electric | Power: 90 | Accuracy: 100%)


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 9: HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

showNames :: [String] -> String
showNames []     = "(none)"
showNames [x]    = x
showNames (x:xs) = x ++ ", " ++ showNames xs

-- EXPLANATION:
--  This is a RECURSIVE FUNCTION using PATTERN MATCHING on a list.
--
--  Haskell lists have two forms:
--    []     — the empty list
--    (x:xs) — x is the head (first element), xs is the tail (rest of list)
--    [x]    — sugar for (x:[]), a list with exactly one element
--
--  Case 1: empty list     → return "(none)"
--  Case 2: one element    → return just that element, no comma
--  Case 3: head + rest    → return head, then ", ", then recurse on the rest
--
--  Example trace: showNames ["Thunderbolt", "QuickAttack"]
--    = "Thunderbolt" ++ ", " ++ showNames ["QuickAttack"]
--    = "Thunderbolt" ++ ", " ++ "QuickAttack"
--    = "Thunderbolt, QuickAttack"
--
--  This is used by Show Monster (to display moves) and Show Decl.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 10: ENVIRONMENT
-- ═══════════════════════════════════════════════════════════════════════════

type MonsterEnv = [(MonsterName, Monster)]
type MoveEnv    = [(MoveName, Move)]
type Env        = (MonsterEnv, MoveEnv)

-- EXPLANATION:
--  An ENVIRONMENT maps names to values — it's how the evaluator remembers
--  what has been declared.
--
--  MonsterEnv is an ASSOCIATION LIST: a list of (name, value) pairs.
--    [(MonsterName, Monster)] = [("Pikachu", Monster "Pikachu" ...)]
--
--  MoveEnv is the same idea for moves.
--
--  Env is a TUPLE of both environments. We need two separate ones because
--  monsters and moves are in different namespaces.
--
--  `lookup key list` is a Haskell Prelude function that searches an
--  association list. It returns Maybe a — either Just value or Nothing.
--  We use lookup extensively in the evaluator instead of writing our own
--  search function.

emptyEnv :: Env
emptyEnv = ([], [])

-- EXPLANATION:
--  The starting environment has no monsters and no moves declared yet.
--  It's a pair of two empty lists.
--  evalProgram starts with emptyEnv and the evaluator builds it up as it
--  processes DeclStmt statements.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 11: PRETTY PRINTER
-- ═══════════════════════════════════════════════════════════════════════════

printProgram :: Program -> IO ()
printProgram (Program stmts) = do
  putStrLn "+-------- MonLang Program --------+"
  mapM_ (\s -> putStrLn ("  " ++ show s)) stmts
  putStrLn "+---------------------------------+"

-- EXPLANATION:
--  printProgram shows the SOURCE of a program (not the evaluated result).
--  It's the "pretty printer" the rubric requires.
--
--  `IO ()` means this function performs I/O and returns nothing (unit).
--  `do` notation sequences multiple IO actions one after another.
--  `putStrLn` prints a String followed by a newline.
--
--  `mapM_` is like `map` but for IO actions, and it throws away the results.
--    mapM_ f [a, b, c]  runs  f a, then f b, then f c
--  The lambda `(\s -> putStrLn ("  " ++ show s))` takes a Stmt, converts it
--  to String with show, indents it with 2 spaces, and prints it.
--
--  The result looks like:
--    +-------- MonLang Program --------+
--      monster Pikachu { ... }
--      print Pikachu
--    +---------------------------------+


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 12: EVALUATOR
-- ═══════════════════════════════════════════════════════════════════════════

evalProgram :: Program -> IO ()
evalProgram (Program stmts) = evalStmts stmts emptyEnv

-- EXPLANATION:
--  Entry point for evaluation. Unwraps the Program, gets the statement list,
--  and starts evaluating with an empty environment.
--  Pattern matching destructures `Program stmts` to extract the list.

evalStmts :: [Stmt] -> Env -> IO ()
evalStmts [] _ = return ()
evalStmts (s:ss) env@(mEnv, mvEnv) =
  case s of
    DeclStmt (MonsterDecl name t stats ab moves) ->
      evalStmts ss ((name, Monster name t stats ab moves) : mEnv, mvEnv)

    DeclStmt (MoveDecl name pow acc t) ->
      evalStmts ss (mEnv, (name, Move name pow acc t) : mvEnv)

    PrintStmt name ->
      case lookup name mEnv of
        Just m  -> putStrLn (show m) >> evalStmts ss env
        Nothing -> putStrLn ("Error: monster \"" ++ name ++ "\" not found")
                   >> evalStmts ss env

    Apply monName mvName ->
      case (lookup monName mEnv, lookup mvName mvEnv) of
        (Just mon, Just mv) ->
          putStrLn (useMove mon mv) >> evalStmts ss env
        (Nothing, _) ->
          putStrLn ("Error: monster \"" ++ monName ++ "\" not found")
          >> evalStmts ss env
        (_, Nothing) ->
          putStrLn ("Error: move \"" ++ mvName ++ "\" not found")
          >> evalStmts ss env

    Battle n1 n2 ->
      case (lookup n1 mEnv, lookup n2 mEnv) of
        (Just m1, Just m2) -> runBattle m1 m2 mvEnv >> evalStmts ss env
        (Nothing, _)       -> putStrLn ("Error: monster \"" ++ n1 ++ "\" not found")
                              >> evalStmts ss env
        (_, Nothing)       -> putStrLn ("Error: monster \"" ++ n2 ++ "\" not found")
                              >> evalStmts ss env

-- EXPLANATION OF evalStmts:
--
--  This is the CORE of the interpreter. It takes:
--    [Stmt]  — the remaining statements to process
--    Env     — the current environment (what's been declared so far)
--  and returns IO () (performs side effects like printing).
--
--  BASE CASE: evalStmts [] _ = return ()
--    When there are no more statements, stop. `return ()` does nothing.
--    The underscore _ means "ignore the environment".
--
--  RECURSIVE CASE: evalStmts (s:ss) env@(mEnv, mvEnv)
--    (s:ss)          — pattern match: s is the current stmt, ss is the rest
--    env@(mEnv, mvEnv) — `@` is an AS-PATTERN: binds the whole tuple to `env`
--                        AND destructures it into mEnv and mvEnv at once.
--
--  HOW THE ENVIRONMENT GROWS (DeclStmt):
--    MonsterDecl: builds a Monster from the fields, prepends it to mEnv.
--      `(name, Monster ...) : mEnv` adds a new (name, Monster) pair to the front.
--      Then recurses with the updated env.
--    MoveDecl: same idea, but adds to mvEnv instead.
--    Note: we pass the UPDATED env to the recursive call — this is how
--    later statements can see earlier declarations.
--
--  PrintStmt:
--    `lookup name mEnv` searches the association list for the monster's name.
--    Returns Maybe Monster — Just m if found, Nothing if not.
--    `show m` uses our custom Show Monster instance to format the output.
--    `>>` sequences two IO actions: do the first, then do the second.
--    We pass the UNCHANGED env (printing doesn't add anything).
--
--  Apply:
--    Looks up BOTH the monster and the move simultaneously using a tuple.
--    `(lookup monName mEnv, lookup mvName mvEnv)` gives (Maybe Monster, Maybe Move).
--    Pattern matches on the pair — requires both to be Just for success.
--    `_` in the pattern means "I don't care what this is".
--
--  Battle:
--    Looks up both monsters (both in mEnv, the monster namespace).
--    Calls runBattle which handles the full fight logic, then continues.

useMove :: Monster -> Move -> String
useMove (Monster mname _ _ _ _) (Move mvname pow acc _) =
  mname ++ " used " ++ mvname ++ "! " ++
  "(Power: " ++ show pow ++ ", Accuracy: " ++ show acc ++ "%)"

-- EXPLANATION:
--  useMove formats the "apply" output without running a battle.
--  The underscores _ discard the fields we don't need (type, stats, ability,
--  moves from Monster; type from Move). We only need the names, power, accuracy.
--  This is called by the Apply case in evalStmts.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 13: BATTLE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

typeEffectiveness :: Type -> Type -> Double
typeEffectiveness mvType defType = case (mvType, defType) of
  (Water,    Fire)    -> 2.0
  (Fire,     Grass)   -> 2.0
  (Grass,    Water)   -> 2.0
  (Electric, Water)   -> 2.0
  (Fire,     Water)   -> 0.5
  (Grass,    Fire)    -> 0.5
  (Water,    Grass)   -> 0.5
  _                   -> 1.0

-- EXPLANATION:
--  Takes the MOVE's type and the DEFENDER's type, returns a multiplier.
--  Uses a tuple pattern match: `case (mvType, defType) of`
--    2.0 = super effective  (move type beats defender type)
--    0.5 = not very effective (move type is weak against defender type)
--    1.0 = neutral (wildcard _ catches all other combinations)
--
--  The type chart implemented (rock-paper-scissors style):
--    Water > Fire > Grass > Water  (cycle)
--    Electric > Water
--    Everything else is neutral (1.0)
--
--  Double is Haskell's 64-bit floating point type.
--  We need Float/Double here because the multiplier is 0.5 (not an integer).

calcDamage :: Int -> MoveName -> Type -> Int -> MoveEnv -> Int
calcDamage atk mvName defType def mvEnv =
  case lookup mvName mvEnv of
    Nothing              -> 0
    Just (Move _ pow _ mvType) ->
      let base = (atk * pow) `div` (def * 5)
          eff  = typeEffectiveness mvType defType
      in  floor (fromIntegral base * eff)

-- EXPLANATION:
--  Calculates how much damage a move deals.
--
--  Parameters:
--    atk     — attacker's attack stat
--    mvName  — name of the move being used
--    defType — defender's element type (for type effectiveness)
--    def     — defender's defense stat
--    mvEnv   — the move environment (to look up the move's power and type)
--
--  `lookup mvName mvEnv` — finds the Move in the environment.
--    If not found (Nothing), return 0 damage.
--    If found, pattern match to extract pow and mvType.
--      `_` discards the move name and accuracy we don't need here.
--
--  Damage formula:
--    base = (attacker ATK × move power) ÷ (defender DEF × 5)
--    `div` is INTEGER DIVISION (truncates, no remainder kept)
--    eff  = type effectiveness multiplier (2.0, 0.5, or 1.0)
--    final damage = floor(base × eff)
--
--  `let ... in ...` creates LOCAL VARIABLES inside an expression.
--  `fromIntegral base` converts Int → Double so we can multiply by eff (Double).
--  `floor` rounds a Double DOWN to the nearest Int.
--    floor 15.9 = 15,  floor 30.0 = 30

runBattle :: Monster -> Monster -> MoveEnv -> IO ()
runBattle m1@(Monster n1 t1 (Stats hp1 atk1 def1 spd1) _ mvs1)
          m2@(Monster n2 t2 (Stats hp2 atk2 def2 spd2) _ mvs2)
          mvEnv = do
  putStrLn ("*** Battle: " ++ n1 ++ " vs " ++ n2 ++ " ***")
  if spd1 >= spd2
    then battleLoop n1 t1 hp1 atk1 def1 mvs1
                    n2 t2 hp2 atk2 def2 mvs2 mvEnv
    else battleLoop n2 t2 hp2 atk2 def2 mvs2
                    n1 t1 hp1 atk1 def1 mvs1 mvEnv

-- EXPLANATION:
--  runBattle is the ENTRY POINT for a battle. It does two things:
--    1. Print the battle header.
--    2. Decide who goes first based on speed, then call battleLoop.
--
--  Pattern matching extracts all fields from both monsters.
--    `m1@(Monster n1 ...)` — the @ binds the whole Monster to m1, AND
--    destructures it to get the individual fields n1, t1, etc.
--    (Stats hp1 atk1 def1 spd1) — nested pattern match inside the Stats field.
--    `_` discards the Ability field (not needed in battle).
--
--  `if spd1 >= spd2` — faster monster attacks first (higher SPD goes first).
--    If spd1 >= spd2: m1 is attacker, m2 is defender.
--    Otherwise:       m2 is attacker, m1 is defender.
--  This is the ONLY place where argument order matters for fairness.

battleLoop :: String -> Type -> Int -> Int -> Int -> [MoveName]
           -> String -> Type -> Int -> Int -> Int -> [MoveName]
           -> MoveEnv -> IO ()
battleLoop an at ahp aatk adef amvs dn dt dhp datk ddef dmvs mvEnv
  | ahp <= 0  = putStrLn (an ++ " fainted! " ++ dn ++ " wins!")
  | dhp <= 0  = putStrLn (dn ++ " fainted! " ++ an ++ " wins!")
  | null amvs = putStrLn (an ++ " has no moves! " ++ dn ++ " wins!")
  | otherwise = do
      let mv   = head amvs
          dmg  = calcDamage aatk mv dt ddef mvEnv
          dhp' = max 0 (dhp - dmg)
          mvType = case lookup mv mvEnv of
                     Just (Move _ _ _ t) -> t
                     Nothing             -> Normal
          eff    = typeEffectiveness mvType dt
          effMsg = if eff > 1.0 then " It's super effective!"
                   else if eff < 1.0 then " It's not very effective..."
                   else ""
      putStrLn (an ++ " used " ++ mv ++ "!" ++ effMsg
                ++ " (" ++ show dmg ++ " dmg) "
                ++ dn ++ " HP: " ++ show dhp')
      battleLoop dn dt dhp' datk ddef dmvs
                 an at ahp  aatk adef amvs mvEnv

-- EXPLANATION:
--  battleLoop is a RECURSIVE FUNCTION that simulates one turn at a time.
--
--  Parameters (attacker first, then defender):
--    an   — attacker name (String)
--    at   — attacker type (Type)
--    ahp  — attacker current HP (Int)
--    aatk — attacker attack stat
--    adef — attacker defense stat
--    amvs — attacker's move list ([MoveName])
--    dn, dt, dhp, datk, ddef, dmvs — same for defender
--    mvEnv — the move environment for looking up move stats
--
--  GUARD CLAUSES (lines starting with |):
--    Guards are checked in order. The first True guard executes.
--    | ahp <= 0  — attacker already fainted (shouldn't normally happen)
--    | dhp <= 0  — defender fainted → defender loses
--    | null amvs — attacker has no moves → they forfeit
--    | otherwise — normal turn: always True, runs the battle logic
--
--  INSIDE THE TURN (let block):
--    mv   = head amvs     — take the first move in the attacker's list
--                           head returns the first element of a list
--    dmg  = calcDamage ... — calculate damage using our formula
--    dhp' = max 0 (dhp - dmg) — subtract damage, but HP can't go below 0
--                               max 0 x = x if x > 0, else 0
--    mvType — look up the move's element type for the effectiveness message
--    eff    — get the type multiplier
--    effMsg — choose the message string based on the multiplier
--             we use > 1.0 and < 1.0 instead of == 2.0 / == 0.5 to avoid
--             floating point comparison warnings from GHC
--
--  THE SWAP (last line of battleLoop):
--    battleLoop dn dt dhp' datk ddef dmvs
--               an at ahp  aatk adef amvs mvEnv
--    Notice: attacker and defender SWITCH POSITIONS.
--    dn (old defender) is now the new attacker (an).
--    an (old attacker) is now the new defender (dn).
--    dhp' (defender's new HP after damage) is passed as the new ahp.
--    This is how turns alternate — no mutable state needed.
--    The recursion continues until a guard catches ahp<=0 or dhp<=0.


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 14: EXAMPLE PROGRAMS
-- ═══════════════════════════════════════════════════════════════════════════

-- Print and apply demo
prog1 :: Program
prog1 = Program
  [ DeclStmt (MonsterDecl "Pikachu" Electric (Stats 35 55 40 90) "Static"
                           ["Thunderbolt", "QuickAttack"])
  , DeclStmt (MoveDecl "Thunderbolt" 90 100 Electric)
  , PrintStmt "Pikachu"
  , Apply "Pikachu" "Thunderbolt"
  , PrintStmt "Raichu"
  ]

-- EXPLANATION:
--  prog1 demonstrates DeclStmt, PrintStmt, and Apply.
--  Declares Pikachu (Electric, with 2 moves) and the Thunderbolt move.
--  PrintStmt "Pikachu" → looks up Pikachu in mEnv, prints its Monster card.
--  Apply "Pikachu" "Thunderbolt" → looks up both, calls useMove, prints result.
--  PrintStmt "Raichu" → Raichu was never declared → prints error message.
--  This shows the error handling: the evaluator continues after the error.

-- Two-monster battle: Electric beats Water
prog2 :: Program
prog2 = Program
  [ DeclStmt (MonsterDecl "Pikachu"  Electric (Stats 35 55 40 90) "Static"  ["Thunderbolt"])
  , DeclStmt (MonsterDecl "Squirtle" Water    (Stats 44 48 65 43) "Torrent" ["WaterGun"])
  , DeclStmt (MoveDecl "Thunderbolt" 90 100 Electric)
  , DeclStmt (MoveDecl "WaterGun"    40 100 Water)
  , Battle "Pikachu" "Squirtle"
  ]

-- EXPLANATION:
--  prog2 demonstrates Battle.
--  Pikachu (SPD 90) is faster than Squirtle (SPD 43), so Pikachu goes first.
--  Electric vs Water → typeEffectiveness Electric Water = 2.0 (super effective).
--  Water vs Electric → typeEffectiveness Water Electric = 1.0 (neutral).
--  Pikachu's higher speed + super effective moves = Pikachu wins.

-- Fire vs Grass: type advantage flips the outcome
prog3 :: Program
prog3 = Program
  [ DeclStmt (MonsterDecl "Charmander" Fire  (Stats 39 52 43 65) "Blaze"    ["Ember"])
  , DeclStmt (MonsterDecl "Bulbasaur"  Grass (Stats 45 49 49 45) "Overgrow" ["VineWhip"])
  , DeclStmt (MoveDecl "Ember"    40 100 Fire)
  , DeclStmt (MoveDecl "VineWhip" 45 100 Grass)
  , Battle "Charmander" "Bulbasaur"
  ]

-- EXPLANATION:
--  prog3 demonstrates type advantage overcoming stat differences.
--  Charmander (SPD 65) is faster than Bulbasaur (SPD 45), goes first.
--  Fire vs Grass → super effective (2.0x) — Ember does extra damage.
--  Grass vs Fire → not very effective (0.5x) — VineWhip does reduced damage.
--  Charmander wins despite Bulbasaur having more HP (45 vs 39).


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 15: MAIN
-- ═══════════════════════════════════════════════════════════════════════════

main :: IO ()
main = do
  putStrLn "=== MonLang Interpreter ===\n"

  putStrLn "--- Program 1 (source) ---"
  printProgram prog1
  putStrLn "--- Evaluating Program 1 ---"
  evalProgram prog1

  putStrLn "\n--- Program 2 (source) ---"
  printProgram prog2
  putStrLn "--- Evaluating Program 2 ---"
  evalProgram prog2

  putStrLn "\n--- Program 3 (source) ---"
  printProgram prog3
  putStrLn "--- Evaluating Program 3 ---"
  evalProgram prog3

-- EXPLANATION:
--  main is the entry point of the Haskell program.
--  `IO ()` means it runs in the IO monad and returns unit (nothing).
--  `do` notation sequences the IO actions top to bottom.
--
--  For each program, we:
--    1. printProgram — show the source (CFG/AST pretty-printed)
--    2. evalProgram  — run the interpreter and show the output
--
--  This satisfies the rubric requirement:
--    "Prints at least one example program (using custom pretty printer)"
--    "Evaluates that program"
--
--  `\n` inside a string literal inserts a blank line in the output.

-- Build & run:
--   ghc Main.hs -o Main
--   .\Main.exe


-- ═══════════════════════════════════════════════════════════════════════════
--  SECTION 16: COMMON Q&A PREP
-- ═══════════════════════════════════════════════════════════════════════════
--
--  Q: "Is this program possible in your language?" — WHAT TO CHECK:
--    - Does it only declare monsters and moves? → YES, supported
--    - Does it use print, apply, or battle? → YES, supported
--    - Does it use variables, loops, arithmetic, strings? → NO, not supported
--    - Does it use types other than Fire/Water/Electric/Grass/Normal? → NO
--    - Does it use more than 4 stats? → NO, exactly hp/atk/def/spd
--
--  Q: "Explain evalStmts"
--    It processes statements one at a time, left to right. For declarations,
--    it adds to the environment and recurses with the updated env. For actions
--    (print, apply, battle), it looks up names in the environment, performs
--    the action, and recurses with the same env unchanged.
--
--  Q: "Explain battleLoop"
--    It's a recursive function that simulates one turn per call. The attacker
--    hits the defender, we subtract damage from the defender's HP, then
--    the two sides swap roles (defender becomes attacker) and we recurse.
--    It stops when either monster's HP drops to 0 or below.
--
--  Q: "What does `lookup` do?"
--    `lookup` is a Prelude function that searches an association list
--    (a list of key-value pairs) for a given key. It returns Maybe a —
--    Just value if found, Nothing if not. We use it to find monsters and
--    moves by name in the environment.
--
--  Q: "What does `>>`  do?"
--    `>>` sequences two IO actions. `a >> b` means "do a, throw away the
--    result, then do b". We use it to print something AND then continue
--    evaluating the rest of the statements.
--
--  Q: "What is `floor` / `fromIntegral`?"
--    `fromIntegral` converts any integral type (like Int) to any numeric type
--    (like Double). We need this because you can't multiply Int * Double directly.
--    `floor` rounds a Double down to the nearest integer. Both are in Prelude
--    (Haskell's standard library) — no imports needed.
--
--  Q: "What is `mapM_`?"
--    `mapM_` applies an IO-producing function to every element of a list,
--    running each action in order and discarding results. The underscore means
--    "discard the results". We use it in printProgram to print each statement.
--
--  Q: "What is `unlines`?"
--    `unlines` takes a list of strings and joins them with newlines. It's a
--    Prelude function. We use it in Show Program to display each statement on
--    its own line.
--
--  Q: "Why two separate environments (MonsterEnv and MoveEnv)?"
--    Monsters and moves are in different namespaces — a move named "Pikachu"
--    would be distinct from a monster named "Pikachu". Keeping them separate
--    also prevents Apply from accidentally accepting a monster name as a move.
--    This mirrors the CFG having <mon-id> and <move-id> as separate rules.
--
--  Q: "Can a monster battle itself?"
--    Yes — `battle Pikachu Pikachu` would compile and run. Both lookups would
--    find the same Monster value. The battle would be symmetric. This is a
--    limitation of the current design — a real language might add a check.
--
--  Q: "What Haskell features does this language use?"
--    - Algebraic data types (data) for AST nodes
--    - Type aliases (type) for readable signatures
--    - Pattern matching (case, function arguments) everywhere
--    - Type classes and instances (Show) for polymorphic printing
--    - Recursion instead of loops (evalStmts, battleLoop, showNames)
--    - The IO monad (do notation, putStrLn, >>) for side effects
--    - Association lists + lookup for the environment
--    - Higher-order functions (map, mapM_, filter via guards)
