import Lake
open Lake DSL

package viper

@[defaultTarget]
lean_exe viper {
  root := `Main
}

-- how to import these from `Viper.Utils`?

inductive CmdResult
  | ok  : String → CmdResult
  | err : String → CmdResult

def List.pop : (l : List α) → l ≠ [] → α × Array α
  | a :: as, _ => (a, ⟨as⟩)

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

def getCurrDir : IO String := do
  match ← runCmd "pwd" with
  | .ok res => return res.trim
  | _ => unreachable!

def getHomeDir : IO String :=
  return s!"{"/".intercalate $ (← getCurrDir).splitOn "/" |>.take 3}"

script setup do
  IO.println "building viper..."
  match ← runCmd "lake build" with
  | .ok  _   =>
    let mut binDir : String := s!"{← getHomeDir}/.local/bin"
    IO.print s!"target directory for the viper binary? (default={binDir}) "
    let input := (← (← IO.getStdin).getLine).trim
    if !input.isEmpty then
      binDir := input
    match ← runCmd s!"cp build/bin/viper {binDir}/viper" with
    | .ok _    => IO.println s!"viper binary placed at {binDir}/"; return 0
    | .err res => IO.eprintln res; return 1
  | .err res => IO.eprintln res; return 1
