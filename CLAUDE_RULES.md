# Claude Code Development Rules

These rules apply to every code generation request.

## General Rules

- Always read PROJECT_CONTEXT.md before generating code.
- Follow PROJECT_CONTEXT.md as the single source of truth.
- Never ignore project requirements.
- Never redesign the project architecture unless explicitly asked.
- Never remove existing functionality without confirmation.
- Never rename files or folders unless instructed.

---

## Coding Standards

- Follow Clean Architecture.
- Follow SOLID Principles.
- Write production-quality code.
- Keep code modular.
- Avoid duplicate code.
- Use reusable components.
- Use meaningful variable names.
- Separate UI, business logic, and database logic.

---

## Flutter Rules

- Use Material 3.
- Keep widgets small and reusable.
- Never put business logic inside widgets.
- Use Provider/Riverpod for state management.
- Follow the project folder structure.

---

## Backend Rules

- Use Express.js.
- Use Prisma ORM.
- PostgreSQL is the only database.
- Validate every request.
- Handle all exceptions.
- Return meaningful HTTP responses.
- Never hardcode secrets.

---

## Database Rules

- Never change database schema without approval.
- Always use Prisma migrations.
- Use foreign keys correctly.
- Follow normalization.
- Never duplicate data unnecessarily.

---

## Git Rules

- Never modify unrelated files.
- Never overwrite existing work.
- Explain major changes before implementing.
- Generate clean commit messages when requested.

---

## UI Rules

- Follow the Figma design.
- Keep the Black + Red theme.
- Material 3 only.
- Responsive layouts.
- Smooth animations.
- Professional fintech appearance.

---

## AI Behaviour

Before writing code:

1. Understand the task.
2. Read PROJECT_CONTEXT.md.
3. Explain the implementation plan.
4. Then generate code.

If requirements are unclear,
ask questions before coding.

Always act like:

- Senior Flutter Engineer
- Senior Node.js Engineer
- Senior PostgreSQL Architect
- Senior FinTech System Architect