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
mkdir -p .claude/skills/run-phase
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

# Download close-phase skill
echo "Downloading close-phase skill..."
curl -sL "$REPO_URL/.claude/skills/close-phase/SKILL.md" -o ".claude/skills/close-phase/SKILL.md"

# Download ralph.sh
echo "Downloading ralph.sh..."
curl -sL "$REPO_URL/scripts/ralph.sh" -o "scripts/ralph.sh"
chmod +x scripts/ralph.sh

# Download workflow reference
echo "Downloading workflow reference..."
curl -sL "$REPO_URL/README.md" -o "ralph-specs/WORKFLOW.md"

# Create .gitkeep files
touch ralph-specs/specs/.gitkeep ralph-specs/docs/.gitkeep ralph-specs/prompts/.gitkeep

# Create settings.local.json if it doesn't exist
if [ ! -f ".claude/settings.local.json" ]; then
    echo "Creating .claude/settings.local.json..."
    cat > .claude/settings.local.json << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(./scripts/ralph.sh*)",
      "Bash(make *)",
      "Bash(npm *)",
      "Bash(docker compose*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git branch*)",
      "Bash(curl*)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git merge*)",
      "Bash(git checkout development*)",
      "Bash(git checkout main*)",
      "Bash(git switch development*)",
      "Bash(git switch main*)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)",
      "Bash(git branch -d development)",
      "Bash(git branch -D development)",
      "Bash(git branch -d main)",
      "Bash(git branch -D main)"
    ]
  }
}
SETTINGS
else
    echo "Settings file already exists, skipping..."
fi

echo ""
echo "Ralph workflow installed successfully!"
echo ""
echo "Installed:"
echo "  Skills:"
echo "    /spec-to-prd  - Create specifications and PRDs from feature ideas"
echo "    /run-phase    - Execute PRD phases with git branching"
echo "    /close-phase  - Verify and merge completed phases"
echo ""
echo "  Files:"
echo "    scripts/ralph.sh            - Context-isolated iteration runner"
echo "    ralph-specs/WORKFLOW.md     - Quick reference guide"
echo "    .claude/settings.local.json - Permissions for autonomous operation"
echo ""
echo "Permissions configured:"
echo "  ✓ Ralph loop can run autonomously"
echo "  ✓ Git push/merge/checkout to main branches requires approval"
echo "  ✓ Dangerous git operations (force push, hard reset) are blocked"
echo ""
echo "Next steps:"
echo "  1. Run /spec-to-prd to create your first specification"
echo "  2. The skill will guide you through discovery and PRD creation"
echo "  3. Use /run-phase <prd-file> to execute phases"
echo "  4. Use /close-phase <prd-file> to complete and merge"
