# scripts\deploy_prod.ps1
$ErrorActionPreference = "Stop"

$Source = "C:\Dev\Git\PZ\TrueMusic_b42-Fix\42"
$Dest   = "C:\Users\conno\Zomboid\Workshop\TrueMusic_b42 Fix\Contents\mods\TrueMusic_b42 Fix\42"

# Crea destino si no existe
robocopy $Source $Dest /MIR /R:2 /W:1 /XF "mod.info" /NFL /NDL /NP | Out-Null

# Mirror del mod hacia PROD
robocopy $Source $Dest /MIR /R:2 /W:1 /NFL /NDL /NP | Out-Null

# Robocopy exit codes: 0-7 = OK, >=8 = error
if ($LASTEXITCODE -ge 8) { exit $LASTEXITCODE } else { exit 0 }
