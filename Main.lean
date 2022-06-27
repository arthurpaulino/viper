import Viper.Linking

def printHelp : IO UInt32 := do
  IO.println "todo: print help"
  return 0

def main (args : List String) : IO UInt32 := do
  mkViperDirs
  match args with
  -- info
  | ["-h"]
  | ["--help"] => printHelp
  | ["links"] => do
    let (_, linksStr, _) ← getLinks
    IO.println linksStr.trim
    return 0
  | ["envs"] => do IO.println s!"{"\t".intercalate (← listEnvs)}"; return 0
  | ["env?"] => do match ← getLinkedEnv with
    | some env => IO.println env; return 0
    | none     => return 0

  -- env creation
  | ["new", env] =>
    withNewEnv env do
      match ← runCmd s!"python3 -m venv {← getEnvsDir}/{env}" with
      | .ok _    => linkEnv env; return 0
      | .err res => IO.eprintln res; return 1
  | ["rename", env, env'] =>
    withNewEnv env do
      let envsDir ← getEnvsDir
      match ← runCmd s!"mv {envsDir}/{env} {envsDir}/{env'}" with
      | .ok _    => relinkEnv env env'; return 0
      | .err res => IO.eprintln res; return 1
  | ["clone", env, env'] =>
    withNewEnv env do
      let envsDir ← getEnvsDir
      match ← runCmd s!"cp {envsDir}/{env} {envsDir}/{env'}" with
      | .ok _    => return 0
      | .err res => IO.eprintln res; return 1
  | "new" :: _ => printHelp
  | "rename" :: _ => printHelp
  | "clone" :: _ => printHelp

  -- env deletion
  | ["del", env] => match ← runCmd s!"rm -rf {← getEnvsDir}/{env}" with
    | .ok _    => unlinkEnv env; return 0
    | .err res => IO.eprintln res; return 1
  | "del" :: _ => printHelp

  -- linking
  | ["link", env] => do linkEnv env; return 0
  | ["unlink"] => do unlinkLocalDir; return 0
  | ["unlink", "dir", dir] => do unlinkDir dir; return 0
  | ["unlink", "env", env] => do unlinkEnv env; return 0
  | "link" :: _ => printHelp
  | "unlink" :: "dir" :: _ => printHelp
  | "unlink" :: "env" :: _ => printHelp

  -- maintenance
  | ["health"] => sorry
  | ["fix"] =>
    mkViperDirs
    let (linksFilePath, linksStr, links) ← getLinks
    match links with
    | some _ => return 0
    | none   => resetLinksTo .empty linksStr; return 0
  | ["prune"] => sorry
  | ["prune!"] => sorry

  -- pip
  | "install" :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPipPath env} install {" ".intercalate args}"
  | "uninstall" :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPipPath env} uninstall {" ".intercalate args}"
  
  -- python
  | "-m" :: pyLib :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPythonPath env} -m {pyLib} {" ".intercalate args}"
  | pyFile :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPythonPath env} {pyFile} {" ".intercalate args}"
  | [] => withLinkedEnv $ fun env => do spawn s!"{← getPythonPath env}"
