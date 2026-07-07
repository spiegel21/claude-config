---
description: Run a shell command, read its output, and answer a question about it
argument-hint: <command> :: <question>
allowed-tools: Bash
---

You are given the output of a shell command. Read it, then answer the question.

The user's input was: $ARGUMENTS
(Format is `<command> :: <question>`. The part before `::` is the command that was run; the part after `::` is the question to answer.)

Command output:
!`echo "$ARGUMENTS" | sed 's/::.*//' | xargs -I{} sh -c '{}' 2>&1`

Based on the command output above, answer the question that follows `::` in the input. Be concise and specific, citing exact values from the output.
