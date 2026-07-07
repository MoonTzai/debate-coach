#!/bin/bash
# Install debate-grill skill for Cursor
# Run from the debate-grill/ directory

RULES_DIR=".cursor/rules"
mkdir -p "$RULES_DIR"
cp SKILL.md "$RULES_DIR/debate-grill.md"
echo "debate-grill installed to $RULES_DIR/debate-grill.md"
echo "Use @debate-grill in Cursor to reference this skill."
