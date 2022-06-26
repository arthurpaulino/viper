import Viper.Linking

def main (args : List String) : IO UInt32 := do
  mkViperDirs
  match args with
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
  | ["link", env] => do linkEnv env; return 0
  | ["unlink"] => do unlinkEnv; return 0
  | ["del", env] => sorry
  | ["envs"] => do match ← listEnvs with
    | some envs =>
      IO.println s!"{"\t".intercalate envs}"
      return 0
    | none => IO.eprintln "envs dir not found"; return 1
  | ["links"] => sorry
  | ["health"] => sorry
  | ["env?"] => sorry
  | ["rename", env, env'] => sorry
  | ["clone", env, env'] => sorry
  | "install" :: libs =>
    match ← getLinkedEnv with
    | some env =>
      spawn s!"{← getPipPath env} install {" ".intercalate libs}"
      return 0
    | none => IO.eprintln s!"env link not found"; return 1
  | "uninstall" :: libs => sorry -- pip stuff
  | "-m" :: pyLib :: args => sorry
  | ["-h"]
  | ["--help"] => sorry
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
