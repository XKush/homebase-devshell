# Wave A–D — platform contract (read-only metadata — no execution, no mutation)
# lib/WorkstationPlatformContract.ps1
#
# Prerequisite: WorkstationEventCore.ps1
# Aggregates layer boundaries and public API surface for architecture lock compliance.

function Get-WorkstationPlatformContract {
    $eventLifecycle = if (Get-Command Get-WorkstationEventLifecycleContract -ErrorAction SilentlyContinue) {
        Get-WorkstationEventLifecycleContract
    } else {
        [ordered]@{}
    }

    return [ordered]@{
        ContractVersion = '1.0.0'
        Lock            = [ordered]@{
            Status    = 'LOCKED'
            SignedAt  = '2026-06-29'
            SpecDoc   = 'internal-docs/charter/PLATFORM-SPEC-SIGNOFF.md'
            Baseline  = 'internal-docs/baselines/platform-spec-wave-abcd-lock.json'
            Hardening = 'Test-WorkstationPlatformHardening.ps1'
        }
        Waves           = [ordered]@{
            A = [ordered]@{
                Role  = 'Profile bootstrap, environment, diagnostics read-only'
                Files = @('HomeBasePaths.ps1', 'WorkstationCommon.ps1', 'ProfileEnvironment.ps1', 'profile/Microsoft.PowerShell_profile.ps1')
            }
            B = [ordered]@{
                Role  = 'Orchestration, command registry, router dispatch'
                Files = @('WorkstationOrchestrator.ps1', 'WorkstationCommandRegistry.ps1', 'WorkstationCommandRouter.ps1')
            }
            C = [ordered]@{
                Role  = 'Observability, events, platform contract, execution trace'
                Files = @('WorkstationCapabilityObservability.ps1', 'WorkstationEventCore.ps1', 'WorkstationPlatformContract.ps1', 'WorkstationExecutionTrace.ps1')
            }
            D = [ordered]@{
                Role  = 'Extension boundary, sandbox runtime, event bridge (no core control)'
                Files = @('WorkstationCapabilityExtensions.ps1', 'WorkstationExtensionEventBridge.ps1', 'WorkstationExtensionRuntime.ps1')
            }
        }
        Registries = [ordered]@{
            CoreCommands = '$script:WorkstationCommandRegistry'
            Extensions   = '$script:WorkstationExtensions'
            Events       = '$script:WorkstationEventBuffer'
            ModuleNote   = 'KGreen.Workstation Get-WorkstationCommandRegistry is a separate module catalog — not Wave B core'
        }
        EventLifecycle = $eventLifecycle
        TraceModel     = [ordered]@{
            Input         = '$script:WorkstationEventBuffer'
            Api           = 'Get-WorkstationExecutionTrace'
            OutputFields  = @('Time', 'Command', 'Layer', 'Capability', 'Status')
            AssignDirect  = $true
            JoinRules     = @(
                'registry key Target → core Capability'
                'command.execute.* → Command from Target'
                'extension.execute.* → Command + extension Capability'
            )
        }
        PublicApi      = [ordered]@{
            WaveA = @('Initialize-WorkstationProfileEnvironment', 'Import-WorkstationProfileModule')
            WaveB = @('Invoke-WorkstationProfile', 'Invoke-WorkstationCommand', 'Get-WorkstationCommandRegistry', 'Get-WorkstationExecutionContext')
            WaveC = @('New-WorkstationEvent', 'New-WorkstationLifecycleEvent', 'Test-WorkstationEventBufferContract', 'Test-WorkstationEventLifecyclePairs', 'Get-WorkstationExecutionTrace', 'Get-WorkstationCapabilityMatrix', 'Get-WorkstationCapabilityUsageReport')
            WaveD = @('Register-WorkstationExtension', 'Invoke-WorkstationExtension', 'New-WorkstationExtensionEvent')
        }
        Boundaries = [ordered]@{
            ExtensionsMustNot  = @('Invoke-WorkstationCommand', 'Invoke-WorkstationProfile', 'Register-WorkstationExtension from EntryPoint side effects on core registries')
            RouterMustNot      = @('Filter by capability', 'Call extensions directly', 'Mutate extension registry')
            EventCoreMustNot   = @('Persist events', 'Analyze or score events', 'Influence routing')
            TraceMustNot       = @('Emit events', 'Execute commands', 'Mutate buffers')
        }
    }
}
