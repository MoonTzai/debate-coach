#!/bin/bash
# Install debate-grill skill for Claude Code
# Run from the debate-grill/ directory

SKILL_DIR=".claude/skills/debate-grill"
mkdir -p "$SKILL_DIR"
cp SKILL.md "$SKILL_DIR/"
echo "debate-grill installed to $SKILL_DIR"
echo "Run /reload-plugins in Claude Code or restart the session."
