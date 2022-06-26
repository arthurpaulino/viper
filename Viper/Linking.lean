import Viper.Utils
import Std

abbrev Links := Std.RBMap String String compare

def Links.empty : Links :=
  .empty

def Links.insert (ls : Links) (dir env : String) : Links :=
  Std.RBMap.insert ls dir env

def Links.erase (ls : Links) (dir : String) : Links :=
  Std.RBMap.erase ls dir

def Links.ofString (s : String) : Option Links := Id.run do
  let mut links : Links := .empty
  let mut wellFormed : Bool := true
  for line in s.trim.splitOn "\n" do
    match line.splitOn " => " with
    | [dir, env] => links := links.insert dir env
    | _ => wellFormed := false; break
  if wellFormed then some links
  else none

def Links.toString (ls : Links) : String :=
  ls.fold (init := default) fun acc dir env => s!"{acc}{dir} => {env}\n"

def resetLinksTo (linksStr : String) (links : Links) : IO Unit := do
  let linksBackupFilePath ← getLinksBackupFilePath
  IO.FS.writeFile linksBackupFilePath linksStr
  IO.eprintln s!"ill-formatted links file. generating a new one. old backup is at {linksBackupFilePath}"
  IO.FS.writeFile (← getLinksFilePath) links.toString

def linkEnv (env : String) : IO Unit := do
  let dir ← getCurrDir
  let linksFilePath ← getLinksFilePath
  let linksStr ← IO.FS.readFile linksFilePath
  match Links.ofString linksStr with
  | some links => IO.FS.writeFile linksFilePath (links.insert dir env).toString
  | none => resetLinksTo linksStr $ Links.empty.insert dir env
-- todo: unite these two functions
def unlinkEnv : IO Unit := do
  let dir ← getCurrDir
  let linksFilePath ← getLinksFilePath
  let linksStr ← IO.FS.readFile linksFilePath
  match Links.ofString linksStr with
  | some links => IO.FS.writeFile linksFilePath (links.erase dir).toString
  | none => resetLinksTo linksStr .empty

def getLinkedEnv : IO $ (Option String) := do
  match Links.ofString (← IO.FS.readFile (← getLinksFilePath)) with
  | some links => return links.find? (← getCurrDir)
  | none       => return none
