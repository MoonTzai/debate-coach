#!/bin/bash
# Install debate-coach skill for Claude Code
# Run from the debate-coach/ directory

SKILL_DIR=".claude/skills/debate-coach"
mkdir -p "$SKILL_DIR"
cp SKILL.md "$SKILL_DIR/"
echo "debate-coach installed to $SKILL_DIR"
echo "Run /reload-plugins in Claude Code or restart the session."
