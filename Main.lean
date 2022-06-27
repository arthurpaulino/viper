import Viper.Linking

def main (args : List String) : IO UInt32 := do
  mkViperDirs
  match args with
  | ["-h"]
  | ["--help"] => sorry
  | ["new", env] => do
    match ← listEnvs with
    | some envs =>
      if envs.contains env then
        IO.eprintln "environment already exists"; return 1
      else
        match ← runCmd s!"python3 -m venv {← getEnvsDir}/{env}" with
        | .ok _ => linkEnv env; return 0
        | _ => IO.eprintln "error creating env"; return 1
    | none => IO.eprintln "envs dir not found"; return 1
  | "new" :: _ => sorry
  | ["link", env] => do linkEnv env; return 0
  | "link" :: _ => sorry
  | ["unlink"] => do unlinkEnv; return 0
  | ["del", env] => sorry
  | "del" :: _ => sorry
  | ["envs"] => do match ← listEnvs with
    | some envs =>
      IO.println s!"{"\t".intercalate envs}"
      return 0
    | none => IO.eprintln "envs dir not found"; return 1
  | ["links"] => do
    let (_, linksStr, _) ← getLinks
    IO.println linksStr.trim
    return 0
  | ["env?"] => do match ← getLinkedEnv with
    | some env => IO.println env; return 0
    | none     => return 0
  | ["rename", env, env'] => sorry
  | "rename" :: _ => sorry
  | ["clone", env, env'] => sorry
  | "clone" :: _ => sorry
  | ["health"] => sorry
  | "install" :: args =>
    match ← getLinkedEnv with
    | some env =>
      spawn s!"{← getPipPath env} install {" ".intercalate args}"
      return 0
    | none => IO.eprintln s!"env link not found"; return 1
  | "uninstall" :: args =>
    match ← getLinkedEnv with
    | some env =>
      spawn s!"{← getPipPath env} uninstall {" ".intercalate args}"
      return 0
    | none => IO.eprintln s!"env link not found"; return 1
  | "-m" :: pyLib :: args =>
    match ← getLinkedEnv with
    | some env =>
      spawn s!"{← getPythonPath env} -m {pyLib} {" ".intercalate args}"
      return 0
    | none => IO.eprintln s!"env link not found"; return 1
  | pyFile :: args =>
    match ← getLinkedEnv with
    | some env =>
      spawn s!"{← getPythonPath env} {pyFile} {" ".intercalate args}"
      return 0
    | none => IO.eprintln s!"env link not found"; return 1
  | [] =>
    match ← getLinkedEnv with
    | some env =>
      spawn s!"{← getPythonPath env}"
      return 0
    | none => IO.eprintln s!"env link not found"; return 1
