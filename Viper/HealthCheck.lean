import Viper.Linking

structure HealthCheck where
  missingDirs  : List String -- directories that don't exist anymore
  missingEnvs  : List String -- envs that don't exist anymore
  unlinkedEnvs : List String -- envs that aren't linked to anything
  deriving Inhabited

def HealthCheck.build : IO HealthCheck := do
  let (linksStr, links) ← getLinks
  let envs ← listEnvs
  let links ← match links with
  | some links => pure links
  | none =>
    let links := Links.empty
    resetLinksTo links linksStr
    pure links
  let mut hc : HealthCheck := default
  let mut linkedEnvs : List String := []
  for (d, e) in links.toList do
    linkedEnvs := e :: linkedEnvs
    if ! (← System.FilePath.pathExists ⟨d⟩) then
      hc := { hc with  missingDirs := d :: hc.missingDirs }
    if ! (← System.FilePath.pathExists ⟨s!"{← getEnvsDir}/{e}"⟩) then
      hc := { hc with  missingEnvs := e :: hc.missingEnvs }
  for e in envs do
    if !linkedEnvs.contains e then
      hc := { hc with  unlinkedEnvs := e :: hc.unlinkedEnvs }
  return hc

def buildIndentedList (items : List String) : String :=
  s!"  {"\n  ".intercalate items}"

def HealthCheck.report (hc : HealthCheck) : String := Id.run do
  let mut report := ""
  if !hc.missingDirs.isEmpty then
    report := report ++ s!"inexistent linked directories:\n{buildIndentedList hc.missingDirs}\n"
  if !hc.missingEnvs.isEmpty then
    report := report ++ s!"inexistent linked environments:\n{buildIndentedList hc.missingEnvs}\n"
  if !hc.unlinkedEnvs.isEmpty then
    report := report ++ s!"unlinked environments:\n{buildIndentedList hc.unlinkedEnvs}\n"
  report.trim