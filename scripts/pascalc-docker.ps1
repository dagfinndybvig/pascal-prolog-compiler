param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PascalArgs
)

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$Version = (Get-Content -Path (Join-Path $RepoRoot 'VERSION') -Raw).Trim()
$Image = if ($env:PASCALC_DOCKER_IMAGE) { $env:PASCALC_DOCKER_IMAGE } else { "pascal-prolog-compiler:$Version" }

if (-not $PascalArgs -or $PascalArgs.Count -eq 0) {
    Write-Host "Usage: ./scripts/pascalc-docker.ps1 <compiler-command> [args...]"
    Write-Host "Example: ./scripts/pascalc-docker.ps1 build-asm examples/comprehensive_test.pas comprehensive_test"
    exit 1
}

docker run --rm `
  -v "${RepoRoot}:/workspace" `
  -w /workspace `
  $Image `
  @PascalArgs
