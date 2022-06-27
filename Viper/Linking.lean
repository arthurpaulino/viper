import Viper.Utils
import Std

abbrev Links := Std.RBMap String String compare

namespace Links

def empty : Links :=
  .empty

-- def eraseEnv (links : Links) (env : String) : Links :=
--   links.fold (init := .empty) fun acc d e =>
--     if e == env then acc else acc.insert d e

def erase (links : Links) (dirs envs : List String) : Links :=
  links.fold (init := .empty) fun acc d e =>
    if dirs.contains d || envs.contains e then acc else acc.insert d e

def ofString (s : String) : Option Links := Id.run do
  let mut links : Links := .empty
  let mut wellFormed : Bool := true
  for line in (s.trim.splitOn "\n" |>.filter fun l => !l.isEmpty) do
    match line.splitOn " => " with
    | [dir, env] => links := links.insert dir env
    | _ => wellFormed := false; break
  if wellFormed then some links
  else none

def toString (ls : Links) : String :=
  ls.fold (init := default) fun acc dir env => s!"{acc}{dir} => {env}\n"

end Links

def resetLinksTo (links : Links) (oldLinksStr : String) : IO Unit := do
  let linksBackupFilePath ← getLinksBackupFilePath
  IO.FS.writeFile linksBackupFilePath oldLinksStr
  IO.eprintln   "ill-formatted links file"
  IO.eprintln   "  - a new one was generated"
  IO.eprintln s!"  - the old backup is at {linksBackupFilePath}"
  IO.FS.writeFile (← getLinksFilePath) links.toString

def getLinks : IO $ (String × Option Links) := do
  let linksFilePath ← getLinksFilePath
  let linksStr ← IO.FS.readFile linksFilePath
  return (linksStr, Links.ofString linksStr)

def getLinks' : IO $ Option Links := do
  let (_, links) ← getLinks
  return links

def withModifiedLinks (f : Links → Links) (eraseWith : Links := .empty) :
    IO Unit := do
  let (linksStr, links) ← getLinks
  match links with
  | some links => IO.FS.writeFile (← getLinksFilePath) (f links).toString
  | none => resetLinksTo eraseWith linksStr

def linkEnv (env : String) : IO Unit := do
  let dir ← getCurrDir
  withModifiedLinks
    (fun links => links.insert dir env)
    (Links.empty.insert dir env)

def unlinkDir (dir : String) : IO Unit :=
  withModifiedLinks $ fun links => links.erase [dir] []

def unlinkLocalDir : IO Unit := do
  unlinkDir (← getCurrDir)

def unlinkEnv (env : String) : IO Unit :=
  withModifiedLinks $ fun links => links.erase [] [env]

def relinkEnv (env env' : String) : IO Unit :=
  withModifiedLinks $ fun links =>
    links.fold (init := .empty) fun acc d e =>
      if e == env then acc.insert d env' else acc.insert d env

def getLinkedEnv : IO $ (Option String) := do
  match ← getLinks' with
  | some links => return links.find? (← getCurrDir)
  | none       => return none

def withLinkedEnv (f : String → IO UInt32) : IO UInt32 := do
  match ← getLinkedEnv with
  | some env => f env
  | none     => IO.eprintln "no linked environment"; return 1
