# Incident Response

Everything for handling a security incident, following the NIST SP 800-61 lifecycle. Pick the folder for the step you are in.

| Step | Folder | Use it to |
|---|---|---|
| Classify | [classification-and-severity/](./classification-and-severity) | Rate impact and urgency and set P0 to P3 with SLAs and escalation |
| Respond | [playbooks/](./playbooks) | Follow the playbook for the attack vector (e-mail, credential, malware and ransomware, data breach and insider, web application, network and cloud) |
| Investigate | [investigation/](./investigation) | Write up the threat investigation |
| Notify | [notification/](./notification) | Draft notices to individuals and authorities |
| Close | [post-incident/](./post-incident) | Run the blameless review after closure |
| Check | [checklists/](./checklists) | Track the NIST 800-61 controls by phase |

Typical flow: classify the case, open the playbook for the vector, record the investigation, notify if personal data is affected, then hold the post-incident review.
