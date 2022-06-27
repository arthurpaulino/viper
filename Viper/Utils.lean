def List.pop : (l : List α) → l ≠ [] → α × Array α
  | a :: as, _ => (a, ⟨as⟩)

inductive CmdResult
  | ok  : String → CmdResult
  | err : String → CmdResult        

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
  else return .ok ""

def spawn (cmd : String) : IO UInt32 := do
  let cmd := cmd.splitOn " "
  if h : cmd ≠ [] then
    let (cmd, args) := cmd.pop h
    let child ← IO.Process.spawn {
      cmd := cmd
      args := args
    }
    child.wait
  else return 0

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

def getEnvDir (env : String) : IO String :=
  return s!"{← getEnvsDir}/{env}"

def getLinksFilePath : IO System.FilePath :=
  return ⟨s!"{← getViperDir}/links"⟩

def getLinksBackupFilePath : IO System.FilePath :=
  return ⟨s!"{← getViperDir}/links_backup"⟩

def listEnvs : IO $ List String := do
  match ← runCmd s!"ls {← getEnvsDir}" with
  | .ok res => return res.trim.replace "\n" " " |>.splitOn " "
  | _ => unreachable!

def withNewEnv (env : String) (u : IO UInt32) : IO UInt32 := do
  if (← listEnvs).contains env then
    IO.eprintln s!"environment '{env}' already exists"; return 1
  else u

def mkViperDirs : IO Unit := do
  let envsDir : System.FilePath := ⟨← getEnvsDir⟩
  if ! (← envsDir.pathExists) then
    IO.FS.createDirAll envsDir
  let linksFilePath ← getLinksFilePath
  if ! (← linksFilePath.pathExists) then
    IO.FS.writeFile linksFilePath "\n"

def getPythonPath (env : String) : IO String :=
  return s!"{← getEnvDir env}/bin/python"

def getPipPath (env : String) : IO String :=
  return s!"{← getEnvDir env}/bin/pip"
