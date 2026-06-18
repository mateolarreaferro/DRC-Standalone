# Dr.C Standalone — attendee mode (Windows). Free tier, one LLM call per turn.
#   powershell -ExecutionPolicy Bypass -File scripts\launch-workshop-attendee.ps1

$env:DRC_PRO_PLUS = "0"
$env:DRC_WORKSHOP_LITE = "1"
& "$PSScriptRoot\launch-drc.ps1"
