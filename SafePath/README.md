# SafePath – Crowd-Sourced Pedestrian Safety and Route Recommendation System

Java 17 + Swing + JDBC + MySQL 8. OOP mini project, GMEC Thrikkakara.

**Read `SAFEPATH_CONTRACT.md` first. It is the single source of truth for all names and signatures.**

## Team split
| Part | Person | Works only in |
|---|---|---|
| DATABASE | (name) | `db/`, `dao/` impls, `util/DatabaseManager` |
| BACKEND  | (name) | `model/`, `exception/`, `service/`, `controller/`, `util/` (rest) |
| FRONTEND | (name) | `ui/`, `Main.java` |

## Setup (everyone)
1. Install JDK 17 and MySQL 8.
2. `git clone <repo-url>`
3. Copy `db/db.properties.template` to `db/db.properties` and put YOUR MySQL password (never commit it).
4. `mysql -u root -p < db/schema.sql` then `mysql -u root -p < db/seed.sql`
5. Compile (from project root):
   - Linux/Mac: `javac -cp "lib/*" -d out $(find src -name "*.java")`
   - Windows: compile from your IDE, with `lib/*.jar` on the classpath.
6. Test DB: `java -cp "out:lib/*" com.safepath.util.DbTest` (Windows: `out;lib/*`)

## Git rules
- Branches: `database`, `backend`, `frontend`. Work on your own branch; merge to `main` via pull request.
- Touch only your own packages (see table). Never edit another person's files; ask them.
- Commit small and often. `git pull` before you start each session.
- Contract changes: agree in chat, one person edits the contract and bumps the version.

## Test logins (from seed.sql)
- Admin: admin@safepath.com / admin123
- Pedestrian: test@safepath.com / test123
