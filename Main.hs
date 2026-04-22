module Main where
-- Main.hs

type MonsterName = String
type MoveName = String

-- Program
data Program = Program [Stmt]

-- Statements
data Stmt
  = DeclStmt Decl
  | PrintStmt MonsterName
  | Apply MonsterName MoveName
  deriving Show

-- Declarations
data Decl
  = MonsterDecl MonsterName Type Stats Ability [MoveName]
  | MoveDecl MoveName Int Int Type
  deriving Show
data Monster = Monster MonsterName Type Stats Ability [MoveName] -- deriving Show
instance Show Monster where
  show (Monster name mtype stats ability moves) =
    "Monster: " ++ name ++ "\n" ++
    "Type: " ++ show mtype ++ "\n" ++
    "Stats: " ++ show stats ++ "\n" ++
    "Ability: " ++ ability ++ "\n" ++
    "Moves: " ++ printMoves moves

printMoves :: [MoveName] -> String
printMoves [] = ""
printMoves [m] = m
printMoves (m:ms) = m ++ ", " ++ printMoves ms

data Move = Move MoveName Int Int Type deriving Show
-- Types
data Type = Fire | Water | Electric | Grass | Normal
  deriving (Show, Eq)

-- Stats
data Stats = Stats Int Int Int Int deriving Show

type Ability = String


-- Environment
type MonsterEnv = [(MonsterName, Monster)]
type MoveEnv = [(MoveName, Move)]
type Env = (MonsterEnv, MoveEnv)

--------------------------------------------------
-- Find Monster
findMonster :: Name -> Env -> Maybe Decl
findMonster _ [] = Nothing
findMonster n (d:ds) =
  case d of
    MonsterDecl name _ _ _ _ ->
      if n == name then Just d else findMonster n ds
    _ -> findMonster n ds

--------------------------------------------------

-- Evaluator
evalProgram :: Program -> IO ()
evalProgram (Program stmts) = evalStmts stmts []

evalStmts :: [Stmt] -> Env -> IO ()
evalStmts [] _ = return ()
evalStmts (s:ss) env =
  case s of
    DeclStmt d ->
      evalStmts ss (d : env)

    PrintStmt name -> do
      case findMonster name env of
        Just m  -> print m
        Nothing -> putStrLn ("Monster not found: " ++ name)
      evalStmts ss env




  {-

  MonLang — Context-Free Grammar

  <program> ::= <statement_list>

<statement_list> ::= <statement>
                   | <statement> <statement_list>

<statement> ::= <declaration>
              | <print_stmt>

<declaration> ::= <monster_decl>
                | <move_decl>
                | <team_decl>

--------------------------------------------------

<monster_decl> ::= "monster" <id> "{" <monster_body> "}"

<monster_body> ::= <type_decl>
                  <stats_decl>
                  <ability_decl>
                  <moves_decl>

<type_decl> ::= "type" <id>

<stats_decl> ::= "stats" "{" <stat_list> "}"

<stat_list> ::= <stat>
              | <stat> <stat_list>

<stat> ::= "hp" <num>
         | "attack" <num>
         | "defense" <num>
         | "speed" <num>

<ability_decl> ::= "ability" <id>

<moves_decl> ::= "moves" "[" <id_list> "]"

--------------------------------------------------

<move_decl> ::= "move" <id> "{" <move_body> "}"

<move_body> ::= "power" <num>
                "accuracy" <num>
                "type" <id>

--------------------------------------------------

<team_decl> ::= "team" <id> "{" <id_list> "}"

--------------------------------------------------

<print_stmt> ::= "print" <id>

--------------------------------------------------

<id_list> ::= <id>
            | <id> "," <id_list>

<id> ::= letter (letter | digit)*

<num> ::= digit+


  monster Pikachu {
  type Electric
  stats {
    hp 35
    attack 55
    defense 40
    speed 90
  }
  ability Static
  moves [Thunderbolt]
}

move Thunderbolt {
  power 90
  accuracy 100
  type Electric
}

print Pikachu

--------------------------------------------------
-}
--Main
prog = Program
        [ DeclStmt (MonsterDecl "Pikachu" Electric (Stats 35 55 40 90) "Static" ["Thunderbolt"])
        , DeclStmt (MoveDecl "Thunderbolt" 90 100 Electric)
        , PrintStmt "Pikachu"
        , PrintStmt "Raichu"   -- not declared → "Monster not found"
        ]
main :: IO ()
main = do
  evalProgram prog
{-
  Expected output for the example program
------------------------------------------------------------
  MonsterDecl "Pikachu" Electric (Stats 35 55 40 90) "Static" ["Thunderbolt"]
  Monster not found: Raichu

ghc Main.hs -o Main
.\Main.exe

-}

