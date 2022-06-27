def List.pop : (l : List α) → l ≠ [] → α × Array α
  | a :: as, _ => (a, ⟨as⟩)

inductive CmdResult
  | ok  : String → CmdResult
  | err : String → CmdResult
  | non : CmdResult

def runCmd (cmd : String) : IO CmdResult := do
  let cmd := cmd.splitOn " "
  if h : cmd ≠ [] then
    let (cmd, args) := cmd.pop h
    let out ← IO.Process.output {
      cmd := cmd
      args := args
    }
    return if out.exitCode != 0 then .err out.stderr
      else .ok out.stdout
  else return .non

def spawn (cmd : String) : IO Unit := do
  let cmd := cmd.splitOn " "
  if h : cmd ≠ [] then
    let (cmd, args) := cmd.pop h
    let child ← IO.Process.spawn {
      cmd := cmd
      args := args
    }
    let _ ← child.wait

def getCurrDir : IO String := do
  match ← runCmd "pwd" with
  | .ok res => return res.trim
  | _ => unreachable!

def getHomeDir : IO String :=
  return s!"{"/".intercalate $ (← getCurrDir).splitOn "/" |>.take 3}"

def getViperDir : IO String :=
  return s!"{← getHomeDir}/.viper"

def getEnvsDir : IO String :=
  return s!"{← getViperDir}/envs"

def getLinksFilePath : IO System.FilePath :=
  return ⟨s!"{← getViperDir}/links"⟩

def getLinksBackupFilePath : IO System.FilePath :=
  return ⟨s!"{← getViperDir}/links_backup"⟩

def listEnvs : IO $ Option (List String) := do
  match ← runCmd s!"ls {← getEnvsDir}" with
  | .ok res => return some $ res.replace "\n" " " |>.splitOn " "
  | _ => return none

def mkViperDirs : IO Unit := do
  let envsDir : System.FilePath := ⟨← getEnvsDir⟩
  if ! (← envsDir.pathExists) then
    IO.FS.createDirAll envsDir
  let linksFilePath ← getLinksFilePath
  if ! (← linksFilePath.pathExists) then
    IO.FS.writeFile linksFilePath "\n"

def getPythonPath (env : String) : IO String :=
  return s!"{← getEnvsDir}/{env}/bin/python"

def getPipPath (env : String) : IO String :=
  return s!"{← getEnvsDir}/{env}/bin/pip"
