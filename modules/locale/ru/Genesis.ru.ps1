# Genesis / Singularity — уникальные тексты HOME BASE

function Get-GenesisTexts {
    return @{
        SingularityTitle = 'SINGULARITY — уникальный отпечаток оператора'
        DnaExplain       = 'OP-DNA = SHA256(MachineGuid + Profile + Module + Git + Trust) — только эта машина'
        ChainExplain     = 'Trust Chain — append-only цепочка live-проб; каждый блок ссылается на предыдущий hash'
        CertificatePath  = 'C:\Security\exports\genesis-certificate.txt'
        GenesisStatePath = 'C:\Logs\Workstation\genesis-state.json'
        ChainPath        = 'C:\Logs\Workstation\trust-chain.jsonl'
        Achieved         = 'SINGULARITY ACHIEVED — integrity + DNA + chain VERIFIED'
        NotYet           = 'Singularity не достигнута — trustcheck · windowsstatus · doctor'
    }
}
