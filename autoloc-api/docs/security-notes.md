# Security notes — AutoLoc API

## Route rules

| Request | Anonymous | USER (`student`) | ADMIN (`admin`) |
|---|---|---|---|
| `GET /api/public/ping` | 200 | 200 | 200 |
| `GET /api/hello` | 401 | 200 | 200 |
| `GET /api/admin/report` | 401 | 403 | 200 |

Rules declared in `SecurityConfig`, evaluated **top to bottom, first match wins**:

1. `/api/public/**` → `permitAll()`
2. `/api/admin/**` → `hasRole("ADMIN")`
3. `/api/**` → `hasAnyRole("USER", "ADMIN")`
4. anything else → `authenticated()`

Authentication uses HTTP Basic.

## Questions

**Why must `/api/admin/**` be declared before `/api/**`?**
Spring Security stops at the first matching rule. `/api/**` also matches `/api/admin/report`, so
if it came first a USER would be let into the admin routes and the ADMIN rule would never be
reached. Specific rules go first, broad rules last.

**401 Unauthorized vs 403 Forbidden?**
401 = authentication failed or missing: the server doesn't know who you are (no or wrong
credentials). 403 = authenticated, but your role is not allowed to access the resource
(`student` on `/api/admin/report`).

**Why BCrypt instead of plain text?**
If the user store leaks, plain-text passwords are directly usable (and often reused on other
sites). BCrypt is a one-way, salted and deliberately slow hash: each hash is unique even for
identical passwords, and brute-forcing is expensive. At login, Spring hashes the submitted
password and compares hashes.

**Why are in-memory users fine here but not in production?**
They are hard-coded in the source code, lost/reset at every restart, cannot be created or changed
at runtime, aren't shared between several instances of the app, and the credentials end up in Git.
That's fine for a classroom demo, not for real users.

**What is needed to load users and roles from MySQL?**
- A `Utilisateur` entity (username, BCrypt password, enabled) and a `Role` entity / enum
  (e.g. `@ManyToMany` or `@ElementCollection`).
- A `UtilisateurRepository` with `findByUsername(String username)`.
- A custom `UserDetailsService` bean that loads the user from the repository and maps it to
  `UserDetails` (roles → `GrantedAuthority` with the `ROLE_` prefix), replacing the
  `InMemoryUserDetailsManager`.
- Passwords stored already encoded with the `PasswordEncoder` (BCrypt), e.g. on sign-up.

## Limitations / reminders

- `student/student123` and `admin/admin123` are classroom-only credentials; never commit real ones.
- CSRF protection is left at its default. It only affects state-changing requests (POST, PUT,
  DELETE); review it before exposing browser-based forms.
- The database password is read from the `DB_PASSWORD` environment variable, not committed.
