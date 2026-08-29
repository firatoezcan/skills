---
name: human-agent-writing
description: Write human-facing agent messages as ordinary coworker communication instead of audit logs. Use for chat, Slack, status updates, handoffs, reviews, PR prose, and technical writing.
---

# Human agent writing

Write for the person reading the message, not for the system that produced it.

## Human conversation

- Lead with the answer, outcome, or decision.
- Use ordinary words and natural sentences. Sound like a coworker.
- Keep chat and Slack short enough to scan on a phone.
- Do not narrate internal workflow, tools, agents, principles, gates, or bookkeeping unless the reader needs that information to act.
- Omit commit hashes, checksums, byte counts, run IDs, test totals, receipt IDs, and similar proof details unless the reader asks for them or they identify the only actionable artifact.
- Do not turn a status update into a review report. Say what works, what is blocked, and what happens next.
- Keep detailed evidence in the PR, issue, test receipt, or handoff. Link that artifact when useful.

## Slack

- Write a person's name on its own line only when the transport needs visible routing. Follow it with a normal message.
- Never expose routing JSON, metadata envelopes, signatures, or machine records in the message body.
- Give each distinct topic or work item its own root message and thread.
- Keep replies in a thread only while they discuss that root topic. Start a new root when the topic changes.
- Distress is feedback, not a blocking approval request. Reply once in the exact distress thread when a response helps.
- Approvals belong in the approval channel. Distress belongs in the distress channel.

## Technical artifacts

Technical writing still needs precision. Put detail where it belongs.

- A review names the verdict and actionable findings first. Include only evidence needed to understand or reproduce a finding.
- A handoff states the current outcome, remaining blocker, and next owner. Do not dump the investigation transcript.
- A PR or issue may carry durable proof, but it should still be readable. Prefer links over copied logs.
- If the user asks for a comprehensive report, include the useful detail. Do not confuse completeness with raw telemetry.

Before sending, ask: would a teammate write this in the same place? If not, rewrite it.
