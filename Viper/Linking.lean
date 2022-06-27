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
  for line in (s.trim.splitOn "\n" |>.filter fun l => !l.isEmpty) do
    match line.splitOn " => " with
    | [dir, env] => links := links.insert dir env
    | _ => wellFormed := false; break
  if wellFormed then some links
  else none

def Links.toString (ls : Links) : String :=
  ls.fold (init := default) fun acc dir env => s!"{acc}{dir} => {env}\n"

def getLinks : IO $ (System.FilePath × String × Option Links) := do
  let linksFilePath ← getLinksFilePath
  let linksStr ← IO.FS.readFile linksFilePath
  return (linksFilePath, linksStr, Links.ofString linksStr)

def resetLinksTo (linksStr : String) (links : Links) : IO Unit := do
  let linksBackupFilePath ← getLinksBackupFilePath
  IO.FS.writeFile linksBackupFilePath linksStr
  IO.eprintln s!"ill-formatted links file. generating a new one. old backup is at {linksBackupFilePath}"
  IO.FS.writeFile (← getLinksFilePath) links.toString

def withModifiedLinks (f g : Links → String → Links) : IO Unit := do
  let dir ← getCurrDir
  let (linksFilePath, linksStr, links) ← getLinks
  match links with
  | some links => IO.FS.writeFile linksFilePath (f links dir).toString
  | none => resetLinksTo linksStr (g .empty dir)

def linkEnv (env : String) : IO Unit :=
  let f := fun links dir => links.insert dir env
  withModifiedLinks f f

def unlinkEnv : IO Unit :=
  withModifiedLinks (fun links dir => links.erase dir) (fun links _ => links)

def getLinkedEnv : IO $ (Option String) := do
  match Links.ofString (← IO.FS.readFile (← getLinksFilePath)) with
  | some links => return links.find? (← getCurrDir)
  | none       => return none
