#!/bin/bash
# Install Ralph workflow into current repository
# Usage: curl -sL https://raw.githubusercontent.com/dearprudence978/ralph-template/main/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/dearprudence978/ralph-template/main"

echo "Installing Ralph workflow..."

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository. Run 'git init' first."
    exit 1
fi

# Check if already installed
if [ -d ".claude/skills/spec-to-prd" ]; then
    echo "Ralph is already installed. Updating..."
fi

# Create directories
echo "Creating directories..."
mkdir -p .claude/skills/spec-to-prd/references
mkdir -p .claude/skills/run-phase/references
mkdir -p .claude/skills/close-phase
mkdir -p scripts
mkdir -p ralph-specs/specs ralph-specs/docs ralph-specs/prompts

# Download spec-to-prd skill
echo "Downloading spec-to-prd skill..."
curl -sL "$REPO_URL/.claude/skills/spec-to-prd/SKILL.md" -o ".claude/skills/spec-to-prd/SKILL.md"
for ref in spec-template.md prd-schema.md prd-template.md progress-template.md example-prd.json tutorial.md; do
    curl -sL "$REPO_URL/.claude/skills/spec-to-prd/references/$ref" -o ".claude/skills/spec-to-prd/references/$ref"
done

# Download run-phase skill
echo "Downloading run-phase skill..."
curl -sL "$REPO_URL/.claude/skills/run-phase/SKILL.md" -o ".claude/skills/run-phase/SKILL.md"
curl -sL "$REPO_URL/.claude/skills/run-phase/references/viewlogs.txt" -o ".claude/skills/run-phase/references/viewlogs.txt"

# Download close-phase skill
echo "Downloading close-phase skill..."
curl -sL "$REPO_URL/.claude/skills/close-phase/SKILL.md" -o ".claude/skills/close-phase/SKILL.md"

# Download setup-ralph skill (self-referencing for future updates)
echo "Downloading setup-ralph skill..."
mkdir -p .claude/skills/setup-ralph
curl -sL "$REPO_URL/.claude/skills/setup-ralph/SKILL.md" -o ".claude/skills/setup-ralph/SKILL.md"

# Download ralph.sh
echo "Downloading ralph.sh..."
curl -sL "$REPO_URL/scripts/ralph.sh" -o "scripts/ralph.sh"
chmod +x scripts/ralph.sh

# Download workflow reference
echo "Downloading workflow reference..."
curl -sL "$REPO_URL/README.md" -o "ralph-specs/WORKFLOW.md"

# Create .gitkeep files
touch ralph-specs/specs/.gitkeep ralph-specs/docs/.gitkeep ralph-specs/prompts/.gitkeep

# --- Settings Configuration ---
# Ralph uses TWO settings files:
#   .claude/settings.json       - Project-level (checked into repo), sandbox + broad permissions
#   .claude/settings.local.json - User-level (gitignored), accumulated per-user permissions
#
# The settings.json provides sandbox mode so Ralph can run autonomously.
# The deny/ask lists protect against destructive operations.

echo "Configuring settings..."

# Download and install settings.json (project-level)
if [ ! -f ".claude/settings.json" ]; then
    echo "Creating .claude/settings.json (project-level sandbox permissions)..."
    curl -sL "$REPO_URL/.claude/settings.json" -o ".claude/settings.json"
else
    echo "Existing .claude/settings.json found. Checking for Ralph settings..."
    # Check if sandbox is already configured
    if grep -q '"autoAllowBashIfSandboxed"' .claude/settings.json 2>/dev/null; then
        echo "  Sandbox already configured, skipping settings.json update."
    else
        echo "  Settings.json exists but lacks sandbox config."
        echo "  Downloading Ralph settings to .claude/settings.ralph.json for manual merge..."
        curl -sL "$REPO_URL/.claude/settings.json" -o ".claude/settings.ralph.json"
        echo ""
        echo "  ACTION REQUIRED: Merge .claude/settings.ralph.json into .claude/settings.json"
        echo "  Key sections to add:"
        echo "    - sandbox.enabled: true"
        echo "    - sandbox.autoAllowBashIfSandboxed: true"
        echo "    - permissions.deny: [destructive git commands]"
        echo "    - permissions.ask: [push, merge, checkout main/development]"
    fi
fi

# Remove old settings.local.json if it only contains Ralph defaults
# (settings.json now handles this at project level)
if [ -f ".claude/settings.local.json" ]; then
    echo "  Note: .claude/settings.local.json exists (user-level overrides preserved)."
fi

echo ""
echo "Ralph workflow installed successfully!"
echo ""
echo "Installed:"
echo "  Skills:"
echo "    /spec-to-prd   - Create specifications and PRDs from feature ideas"
echo "    /run-phase     - Execute PRD phases with git branching"
echo "    /close-phase   - Verify and merge completed phases"
echo "    /setup-ralph   - Reinstall/update Ralph workflow"
echo ""
echo "  Files:"
echo "    scripts/ralph.sh           - Context-isolated iteration runner"
echo "    ralph-specs/WORKFLOW.md    - Quick reference guide"
echo "    .claude/settings.json     - Sandbox + permission guardrails (project-level)"
echo ""
echo "Permission model:"
echo "  Sandbox:  autoAllowBashIfSandboxed = true (autonomous operation)"
echo "  Deny:     Force push, hard reset, delete main/development branches"
echo "  Ask:      Push, merge, rebase, checkout main/development"
echo "  Allow:    All other Bash, Read, Edit, Write, WebSearch, WebFetch"
echo ""
echo "Next steps:"
echo "  1. Run /spec-to-prd to create your first specification"
echo "  2. The skill will guide you through discovery and PRD creation"
echo "  3. Use /run-phase <prd-file> to execute phases"
echo "  4. Use /close-phase <prd-file> to complete and merge"
