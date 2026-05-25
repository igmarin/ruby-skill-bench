# Eval: security-review-process-basic

## Task
Audit the provided Rails codebase for security issues:
1. Identify and resolve any SQL injection vulnerabilities (e.g. direct string interpolation in queries like `#{}`).
2. Verify that input parameters are allowlisted using strong parameters or standard filters.
3. Check for shell injection risks (e.g. use of `system`, backticks, or `exec` with unescaped input).
4. Scan the repository for hardcoded secrets or sensitive credentials.
5. Run dependency auditing using `bundle-audit`.

## Success Criteria
- Vulnerabilities are identified and fixed.
- No SQL injection or shell injection opportunities remain.
- Strong parameter allowlisting is implemented correctly.
