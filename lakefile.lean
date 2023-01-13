import Lake
open Lake DSL

package viper

lean_lib Viper

@[default_target]
lean_exe viper where
  root := `Main

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

def getHomeDir : IO String := do
  match ← IO.getEnv "HOME" with
  | some path => pure path
  | none => throw $ IO.userError "Couldn't find home directory"

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
