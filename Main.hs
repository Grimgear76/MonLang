{- HLINT ignore "Use guards" -}
module Main where


--  MonLang — Context-Free Grammar (CFG)
--
--  AST: data Program = Program [Stmt]
--   <program>       ::= <stmt-list>
--
--   <stmt-list>     ::= <stmt>
--                     | <stmt> <stmt-list>
--
--  AST: data Stmt = DeclStmt Decl | PrintStmt MonsterName
--                 | Apply MonsterName MoveName
--                 | Battle MonsterName MonsterName
--   <stmt>          ::= <decl>
--                     | <print-stmt>
--                     | <apply-stmt>
--                     | <battle-stmt>
--
--  Declarations ---------------------------------------------
--
--  AST: data Decl = MonsterDecl ... | MoveDecl ...
--   <decl>          ::= <monster-decl>
--                     | <move-decl>
--
--  AST: MonsterDecl MonsterName Type Stats Ability [MoveName]
--   <monster-decl>  ::= "monster" <mon-id> "{" <monster-body> "}"
--
--   <monster-body>  ::= "type"    <type>
--                       "stats"   "{" <stat-list> "}"
--                       "ability" <ability>
--                       "moves"   "[" <move-id-list> "]"
--
--  AST: data Stats = Stats Int Int Int Int  (hp atk def spd)
--   <stat-list>     ::= <stat>
--                     | <stat> <stat-list>
--
--   <stat>          ::= "hp"      <num>
--                     | "attack"  <num>
--                     | "defense" <num>
--                     | "speed"   <num>
--
--  AST: MoveDecl MoveName Int Int Type  (name power accuracy type)
--   <move-decl>     ::= "move" <move-id> "{" <move-body> "}"
--
--   <move-body>     ::= "power"    <num>
--                       "accuracy" <num>
--                       "type"     <type>
--
--  Statements -----------------------------------------------
--
--  AST: PrintStmt MonsterName
--   <print-stmt>    ::= "print" <mon-id>
--
--  AST: Apply MonsterName MoveName
--   <apply-stmt>    ::= "apply" <mon-id> <move-id>
--
--  AST: Battle MonsterName MonsterName
--   <battle-stmt>   ::= "battle" <mon-id> <mon-id>
--
--  Shared Non-Terminals ----------------------------------------------
--
--  AST: data Type = Fire | Water | Electric | Grass | Normal
--   <type>          ::= "Fire" | "Water" | "Electric"
--                     | "Grass" | "Normal"
--
--  AST: type Ability = String
--   <ability>       ::= <mon-id>
--
--  AST: type MonsterName = String   (monster namespace)
--   <mon-id>        ::= letter (letter | digit)*
--
--  AST: type MoveName = String      (move namespace)
--   <move-id>       ::= letter (letter | digit)*
--
--   <move-id-list>  ::= <move-id>
--                     | <move-id> "," <move-id-list>
--
--   <num>           ::= digit+
--
-- ------------------------------------------------------------
--  Concrete Syntax Examples
-- ------------------------------------------------------------
--
--   monster Pikachu {            -- MonsterDecl
--     type Electric              --   Type
--     stats {                    --   Stats
--       hp 35  attack 55
--       defense 40  speed 90
--     }
--     ability Static             --   Ability
--     moves [Thunderbolt]        --   [MoveName]
--   }
--
--   move Thunderbolt {           -- MoveDecl
--     power 90                   --   power :: Int
--     accuracy 100               --   accuracy :: Int
--     type Electric              --   Type
--   }
--
--   print Pikachu                -- PrintStmt
--   apply Pikachu Thunderbolt    -- Apply
--   battle Pikachu Squirtle      -- Battle

-- Type Aliases 

type MonsterName = String
type MoveName    = String
type Ability     = String

-- Element Types 

data Type = Fire | Water | Electric | Grass | Normal
  deriving Eq

instance Show Type where
  show Fire     = "Fire"
  show Water    = "Water"
  show Electric = "Electric"
  show Grass    = "Grass"
  show Normal   = "Normal"

-- Stats 

data Stats = Stats Int Int Int Int   -- hp attack defense speed

instance Show Stats where
  show (Stats h a d s) =
    "HP "  ++ show h ++ " / ATK " ++ show a ++
    " / DEF " ++ show d ++ " / SPD " ++ show s

--  AST: Declarations 

data Decl
  = MonsterDecl MonsterName Type Stats Ability [MoveName]
  | MoveDecl    MoveName Int Int Type   -- name power accuracy type

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

-- AST: Statements 

data Stmt
  = DeclStmt  Decl
  | PrintStmt MonsterName
  | Apply     MonsterName MoveName
  | Battle    MonsterName MonsterName

instance Show Stmt where
  show (DeclStmt d)    = show d
  show (PrintStmt n)   = "print " ++ n
  show (Apply mn mv)   = "apply " ++ mn ++ " " ++ mv
  show (Battle n1 n2)  = "battle " ++ n1 ++ " " ++ n2

-- AST: Program 

data Program = Program [Stmt]

instance Show Program where
  show (Program stmts) = unlines (map show stmts)

-- Runtime Values --------------------------------------------

data Monster = Monster MonsterName Type Stats Ability [MoveName]

instance Show Monster where
  show (Monster name t stats ab moves) =
    "[ " ++ name ++ " ]\n" ++
    "  Type    : " ++ show t     ++ "\n" ++
    "  Stats   : " ++ show stats ++ "\n" ++
    "  Ability : " ++ ab         ++ "\n" ++
    "  Moves   : " ++ showNames moves

data Move = Move MoveName Int Int Type

instance Show Move where
  show (Move name pow acc t) =
    name ++ " (" ++ show t ++
    " | Power: " ++ show pow ++
    " | Accuracy: " ++ show acc ++ "%)"

-- Helpers ------------------------------------------------

showNames :: [String] -> String
showNames []     = "(none)"
showNames [x]    = x
showNames (x:xs) = x ++ ", " ++ showNames xs

-- Environment -------------------------------

type MonsterEnv = [(MonsterName, Monster)]
type MoveEnv    = [(MoveName, Move)]
type Env        = (MonsterEnv, MoveEnv)

emptyEnv :: Env
emptyEnv = ([], [])

-- Pretty Printer -------------------------------------------

printProgram :: Program -> IO ()
printProgram (Program stmts) = do
  putStrLn "+-------- MonLang Program --------+"
  mapM_ (\s -> putStrLn ("  " ++ show s)) stmts
  putStrLn "+---------------------------------+"

-- Evaluator --------------------------------------------------------------

evalProgram :: Program -> IO ()              
evalProgram (Program stmts) = evalStmts stmts emptyEnv  -- start evaluating statements with an empty environment

evalStmts :: [Stmt] -> Env -> IO () 
evalStmts [] _ = return ()             --base case: no more statements to evaluate

evalStmts (s:ss) env@(mEnv, mvEnv) =   -- recursive case: evaluate the first statement, then continue with the rest
  case s of    -- pattern match on the type of statement is being evaluated

    DeclStmt (MonsterDecl name t stats ab moves) ->
      evalStmts ss ((name, Monster name t stats ab moves) : mEnv, mvEnv)

    DeclStmt (MoveDecl name pow acc t) ->
      evalStmts ss (mEnv, (name, Move name pow acc t) : mvEnv)

    PrintStmt name ->
      case lookup name mEnv of
        Just m  -> putStrLn (show m) >> evalStmts ss env
        Nothing -> putStrLn ("Error: monster \"" ++ name ++ "\" not found")
                   >> evalStmts ss env

    Apply monName mvName ->     -- look up the monster and move in the environment, then print the result of using the move
      case (lookup monName mEnv, lookup mvName mvEnv) of
        (Just mon, Just mv) ->
          putStrLn (useMove mon mv) >> evalStmts ss env
        (Nothing, _) ->
          putStrLn ("Error: monster \"" ++ monName ++ "\" not found")
          >> evalStmts ss env
        (_, Nothing) ->
          putStrLn ("Error: move \"" ++ mvName ++ "\" not found")
          >> evalStmts ss env

    Battle n1 n2 ->         -- look up both monsters in the environment, then run the battle if both are found
      case (lookup n1 mEnv, lookup n2 mEnv) of
        (Just m1, Just m2) -> runBattle m1 m2 mvEnv >> evalStmts ss env
        (Nothing, _)       -> putStrLn ("Error: monster \"" ++ n1 ++ "\" not found")
                              >> evalStmts ss env
        (_, Nothing)       -> putStrLn ("Error: monster \"" ++ n2 ++ "\" not found")
                              >> evalStmts ss env

useMove :: Monster -> Move -> String  -- create a string describing the monster using the move, including power and accuracy
useMove (Monster mname _ _ _ _) (Move mvname pow acc _) =
  mname ++ " used " ++ mvname ++ "! " ++
  "(Power: " ++ show pow ++ ", Accuracy: " ++ show acc ++ "%)"

-- Battle System ------------------------------------------------------------

-- Type effectiveness: returns 2.0 (super), 0.5 (not very), or 1.0 (neutral)
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

-- Damage = (attacker ATK * move power) / (defender DEF * 5), scaled by type

calcDamage :: Int -> MoveName -> Type -> Int -> MoveEnv -> Int

calcDamage atk mvName defType def mvEnv =

  case lookup mvName mvEnv of  -- look up the move in the environment to get its power and type
    Nothing              -> 0
    Just (Move _ pow _ mvType) ->
      let base = (atk * pow) `div` (def * 5)  -- base damage calculation
          eff  = typeEffectiveness mvType defType
      in  floor (fromIntegral base * eff)

-- Start a battle: faster monster attacks first
runBattle :: Monster -> Monster -> MoveEnv -> IO ()
runBattle m1@(Monster n1 t1 (Stats hp1 atk1 def1 spd1) _ mvs1)
          m2@(Monster n2 t2 (Stats hp2 atk2 def2 spd2) _ mvs2)
          mvEnv = do    
-- Print battle header, then start the battle loop with the faster monster attacking first

  putStrLn ("*** Battle: " ++ n1 ++ " vs " ++ n2 ++ " ***")
  if spd1 >= spd2
    then battleLoop n1 t1 hp1 atk1 def1 mvs1
                    n2 t2 hp2 atk2 def2 mvs2 mvEnv
    else battleLoop n2 t2 hp2 atk2 def2 mvs2
                    n1 t1 hp1 atk1 def1 mvs1 mvEnv

-- Turn-based loop: attacker strikes, then roles swap
battleLoop :: String -> Type -> Int -> Int -> Int -> [MoveName]
           -> String -> Type -> Int -> Int -> Int -> [MoveName]
           -> MoveEnv -> IO ()

battleLoop an at ahp aatk adef amvs dn dt dhp datk ddef dmvs mvEnv  -- attacker/defender names, types, HP, ATK, DEF, moves, and the move environment

  | ahp <= 0  = putStrLn (an ++ " fainted! " ++ dn ++ " wins!") -- if the attacker's HP is 0 or less, they faint and the defender wins
  | dhp <= 0  = putStrLn (dn ++ " fainted! " ++ an ++ " wins!")
  | null amvs = putStrLn (an ++ " has no moves! " ++ dn ++ " wins!")
  | otherwise = do -- attacker uses the first move in their list, calculate damage, print the result, then swap roles for the next turn
      let mv   = head amvs 
          dmg  = calcDamage aatk mv dt ddef mvEnv
          dhp' = max 0 (dhp - dmg)
          mvType = case lookup mv mvEnv of -- look up the move type in the environment for the effectiveness message
                     Just (Move _ _ _ t) -> t
                     Nothing             -> Normal
          eff    = typeEffectiveness mvType dt
          effMsg = if eff > 1.0 then " It's super effective!" -- add a message if the move is super effective, not very effective, or neutral
                   else if eff < 1.0 then " It's not very effective..."
                   else ""
      putStrLn (an ++ " used " ++ mv ++ "!" ++ effMsg
                ++ " (" ++ show dmg ++ " dmg) "
                ++ dn ++ " HP: " ++ show dhp')
      battleLoop dn dt dhp' datk ddef dmvs      -- swap roles for the next turn, with the defender becoming the attacker and vice versa
                 an at ahp  aatk adef amvs mvEnv

-- ─── Example Programs ────────────────────────────────────────────────────────

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

-- Two-monster battle: Electric beats Water
prog2 :: Program
prog2 = Program
  [ DeclStmt (MonsterDecl "Pikachu"  Electric (Stats 35 55 40 90) "Static"  ["Thunderbolt"])
  , DeclStmt (MonsterDecl "Squirtle" Water    (Stats 44 48 65 43) "Torrent" ["WaterGun"])
  , DeclStmt (MoveDecl "Thunderbolt" 90 100 Electric)
  , DeclStmt (MoveDecl "WaterGun"    40 100 Water)
  , Battle "Pikachu" "Squirtle"
  ]

-- Fire vs Grass: type advantage flips the outcome
prog3 :: Program
prog3 = Program
  [ DeclStmt (MonsterDecl "Charmander" Fire  (Stats 39 52 43 65) "Blaze"   ["Ember"])
  , DeclStmt (MonsterDecl "Bulbasaur"  Grass (Stats 45 49 49 45) "Overgrow" ["VineWhip"])
  , DeclStmt (MoveDecl "Ember"    40 100 Fire)
  , DeclStmt (MoveDecl "VineWhip" 45 100 Grass)
  , Battle "Charmander" "Bulbasaur"
  ]

-- Main

main :: IO ()
main = do
  putStrLn "--- MonLang Interpreter ---\n"

  putStrLn "--- Program 1 ---"
  printProgram prog1
  putStrLn "--- Evaluating Program 1 ---"
  evalProgram prog1

  putStrLn "\n--- Program 2 ---"
  printProgram prog2
  putStrLn "--- Evaluating Program 2 ---"
  evalProgram prog2

  putStrLn "\n--- Program 3 ---"
  printProgram prog3
  putStrLn "--- Evaluating Program 3 ---"
  evalProgram prog3

-- Build & run:
--   ghc Main.hs -o Main
--   .\Main.exe
