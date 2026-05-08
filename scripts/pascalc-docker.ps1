param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PascalArgs
)

$Image = if ($env:PASCALC_DOCKER_IMAGE) { $env:PASCALC_DOCKER_IMAGE } else { "pascal-prolog-compiler:1.16.0" }
$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path

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
