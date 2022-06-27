import Viper.Utils
import Viper.Linking
import Viper.HealthCheck

def printHelp : IO UInt32 := do
  IO.println "notation:
  * '$x' means an arbitrary input, to be referenced as `x`
  * '$[⋯ xs]' means an arbitrary sequence of inputs, to be referenced as `xs`"
  IO.println "\nusage: `viper $COMMAND`, where `COMMAND` is:

  #### info
  help                 prints this menu being read
  links                shows the current links
  envs                 displays the list of environments
  env?                 shows the environment linked to this directory

  #### environment management
  new $env             creates a new environment named `env`
  new! $env            runs `new env` and links `env` to the current directory
  rename $env $env'    renames `env` to `env'`, keeping links consistent
  clone $env $env'     clones `env` to a new environment `env'`
  del $env             deletes the environment `env` and its links

  #### linking
  link $env            links the current directory to `env`
  unlink               removes any link for the current directory
  unlink dir $d        removes any link for the directory `d`
  unlink env $e        removes any links to the environment `e`

  #### maintenance
  fix                  if the current links file is corrupted, creates a new
                       (empty) one, backing up the old one
  health               searches for:
                        - inexistent linked directories
                        - inexistent linked environments
                        - unlinked environments
  prune                removes links for inexistent directories and environments
  prune!               runs `prune` but also deletes unlinked environments

  #### pip
  install $[⋯ args]    runs `pip install` with arguments `args`
  uninstall $[⋯ args]  runs `pip uninstall` with arguments `args`

  #### python
  $f $[⋯ args]         runs Python interpreter on file `f` with arguments `args`
  -m $mod $[⋯ args]    runs module `mod` with arguments `args`
  <nil>                runs Python's REPL"
  return 0

def main (args : List String) : IO UInt32 := do
  mkViperDirs
  match args with
  -- info
  | ["help"] => printHelp
  | ["links"] => do
    let (linksStr, _) ← getLinks
    IO.println linksStr.trim
    return 0
  | ["envs"] => do IO.println s!"{"\t".intercalate (← listEnvs)}"; return 0
  | ["env?"] => do match ← getLinkedEnv with
    | some env => IO.println env; return 0
    | none     => return 0

  -- environment management
  | ["new", env] =>
    withNewEnv env do
      match ← runCmd s!"python3 -m venv {← getEnvsDir}/{env}" with
      | .ok _    => return 0
      | .err res => IO.eprintln res; return 1
  | ["new!", env] =>
    withNewEnv env do
      match ← runCmd s!"python3 -m venv {← getEnvsDir}/{env}" with
      | .ok _    => linkEnv env; return 0
      | .err res => IO.eprintln res; return 1
  | ["rename", env, env'] =>
    withNewEnv env' do
      let envsDir ← getEnvsDir
      match ← runCmd s!"mv {envsDir}/{env} {envsDir}/{env'}" with
      | .ok _    => relinkEnv env env'; return 0
      | .err res => IO.eprintln res; return 1
  | ["clone", env, env'] =>
    withNewEnv env' do
      let envsDir ← getEnvsDir
      match ← runCmd s!"cp -r {envsDir}/{env} {envsDir}/{env'}" with
      | .ok _    => return 0
      | .err res => IO.eprintln res; return 1
  | ["del", env] => match ← runCmd s!"rm -rf {← getEnvDir env}" with
    | .ok _    => unlinkEnv env; return 0
    | .err res => IO.eprintln res; return 1
  | "new"    :: _ => printHelp
  | "new!"   :: _ => printHelp
  | "rename" :: _ => printHelp
  | "clone"  :: _ => printHelp
  | "del"    :: _ => printHelp

  -- linking
  | ["link", env] => do linkEnv env; return 0
  | ["unlink"] => do unlinkLocalDir; return 0
  | ["unlink", "dir", dir] => do unlinkDir dir; return 0
  | ["unlink", "env", env] => do unlinkEnv env; return 0
  | "link" :: _ => printHelp
  | "unlink" :: "dir" :: _ => printHelp
  | "unlink" :: "env" :: _ => printHelp

  -- maintenance
  | ["fix"] =>
    let (linksStr, links) ← getLinks
    match links with
    | some _ => return 0
    | none   => resetLinksTo .empty linksStr; return 0
  | ["health"] =>
    let hc ← HealthCheck.build
    let report := hc.report
    if !report.isEmpty then
      IO.println report
    else
      IO.println "viper is healthy, nothing to report"
    return 0
  | ["prune"] =>
    let hc ← HealthCheck.build
    withModifiedLinks $ fun links => links.erase hc.missingDirs hc.missingEnvs
    return 0
  | ["prune!"] => do
    let hc ← HealthCheck.build
    withModifiedLinks $ fun links => links.erase hc.missingDirs hc.missingEnvs
    let envsPaths ← hc.unlinkedEnvs.mapM fun e => do pure $ ← getEnvDir e
    match ← runCmd s!"rm -rf {" ".intercalate envsPaths}" with
    | .ok _    => return 0
    | .err res => IO.eprintln res; return 1

  -- pip
  | "install" :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPipPath env} install {" ".intercalate args}"
  | "uninstall" :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPipPath env} uninstall {" ".intercalate args}"
  
  -- python
  | "-m" :: mod :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPythonPath env} -m {mod} {" ".intercalate args}"
  | pyFile :: args =>
    withLinkedEnv $ fun env => do
      spawn s!"{← getPythonPath env} {pyFile} {" ".intercalate args}"
  | [] => withLinkedEnv $ fun env => do spawn s!"{← getPythonPath env}"
