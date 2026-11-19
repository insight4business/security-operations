# Incident Response Playbooks

One playbook per attack vector, grouped by vector folder, built on the NIST SP 800-61 lifecycle (preparation, detection and analysis, containment, eradication, recovery, post-incident activity). Every playbook has the same 16 sections so analysts always know where to look.

| # | Vector folder | Playbook | Typical first owner |
|---|---|---|---|
| 01 | email-phishing-bec | Phishing | SOC L1 |
| 02 | credential | Credential Compromise | SOC L2 |
| 03 | malware-ransomware | Malware | SOC L2 |
| 04 | malware-ransomware | Ransomware | Incident Commander |
| 05 | data-breach-insider | Data Breach | Privacy Officer and SOC lead |
| 06 | data-breach-insider | Insider Threat | SOC lead with HR and Legal |
| 07 | web-app-api | Web Application Attack | SOC L2 with application owner |
| 08 | network-cloud | Network Intrusion | SOC L2 and Security Engineering |
| 09 | network-cloud | Cloud Account Compromise | Cloud security with SOC L2 |
| 10 | email-phishing-bec | Business E-mail Compromise | SOC L2 with Finance |

## Related templates
- Severity matrix: ../classification-and-severity/severity-matrix.md
- Investigation report: [../investigation](../investigation)
- Post-incident report: [../post-incident](../post-incident)
- Breach notification letter: [../notification](../notification)
- NIST 800-61 checklist: ../checklists/nist-800-61-checklist.csv

## Conventions
- Severity uses P0 (critical) to P3 (low). SLAs and thresholds in the playbooks are examples.
- Times are UTC. Evidence is hashed with SHA-256.
- Contoso Ltd. and example.com addresses are fictional placeholders.
- A new vector starts from _TEMPLATE.md and goes in the folder of its vector.
- Playbooks support analyst judgement; they do not replace it. Escalate when the situation does not fit.
