# Model policy

Which model runs which part of the way-of-work, and how to change it. This is the reference the loops and plugins already encode — change behavior there, document it here.

## The tiers

| Work | Model | Where it's set |
|------|-------|----------------|
| Main loop / orchestration (`/loop-dev`, `/loop-deploy`) | Session model — whatever the user runs Claude Code with | Not pinned; inherits |
| `security` grader | Session model — **never downgrade** | `loop-dev.md` step 4 |
| `code-review` / `bugs` graders | Mid-tier (e.g. sonnet) when the dispatch tool supports per-subagent model selection | `loop-dev.md` step 4 |
| Review sub-agents (`design-reviewer`, `vuln-scanner`, `regression-scanner`, `deploy-checker`, `security-reviewer`) | `sonnet` | `model:` frontmatter in each `agents/*.md` |
| Skills | Inherit the session | No `model:` frontmatter by default |

Rationale: judgment-heavy, adversarial work (security, architecture) gets the biggest model in the room; mechanical review breadth (style, edge-case enumeration) is fine one tier down; nothing below mid-tier ever grades code.

## Pinning a model

- **Agents**: `model: sonnet | opus | haiku` in the agent frontmatter. All five wayworks agents pin `sonnet` today.
- **Skills**: same `model:` frontmatter field (see `shared:create-skill`). Pin only when a skill is deliberately mechanical (haiku) or deliberately heavyweight; unpinned is the right default — the user's session choice should win.
- Model names are aliases, not versions — never write dated model IDs into skills or agents; they rot (this is why `security-scan` carries no model-version claims).

## Local models (Ollama etc.)

Claude Code cannot route individual stages, graders, or sub-agents to a local model — model selection only picks Claude tiers. The supported local path is per-session, not per-stage:

- Run a separate session against an OpenAI/Anthropic-compatible proxy (LiteLLM or similar) via `ANTHROPIC_BASE_URL`, pointing at Ollama.
- Treat that session as a different tool: fine for mechanical batch work (doc summarization, log triage), not wired into the harness loops — the Stop-gate loops assume a model strong enough to fix its own review findings.

Status: the local-model track (unified Ollama store, which workloads move local) is an open work item — see the Linear backlog. When it lands, this file is where the routing decision gets recorded.
