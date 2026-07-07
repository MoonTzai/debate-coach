#!/bin/bash
# Install debate-coach skill for Cursor
# Run from the debate-coach/ directory

RULES_DIR=".cursor/rules"
mkdir -p "$RULES_DIR"
cp SKILL.md "$RULES_DIR/debate-coach.md"
echo "debate-coach installed to $RULES_DIR/debate-coach.md"
echo "Use @debate-coach in Cursor to reference this skill."
