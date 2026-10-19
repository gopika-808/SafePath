# SafePath – Shared Contract (v1.0)

**Paste this ENTIRE file into your AI at the start of every session.**
It is the single source of truth. Names, packages, signatures and table/column names below are FIXED.

## 0. Instructions for the AI (paste-in rule)

> You are helping build ONE part of the SafePath Java Swing + JDBC project. Two other people build the other parts using other AIs. Follow this contract EXACTLY: same package names, class names, method signatures, enum values, table and column names. Do NOT rename, add, remove or change the signature of anything in the contract. If something is missing, put it in a private/helper method inside your own class or write `// CONTRACT-REQUEST: <what is needed>` and tell me. Only write code for the layer I name as mine. Java 17, no external frameworks (Swing + JDBC only; the JDBC driver jar is the only library).

## 1. Team split and ownership

| Part | Owns (writes code for) | Only CALLS |
|---|---|---|
| **DATABASE** | `schema.sql`, `seed.sql`, `db.properties`, package `dao` (all `*DAOImpl`), `util.DatabaseManager` | `model`, `exception` |
| **BACKEND** | packages `model`, `exception`, `service`, `controller`, `util` (except DatabaseManager) | `dao` interfaces |
| **FRONTEND** | package `ui`, `Main.java` | `controller` classes, `model`, `exception`, `util.SessionManager` |

Layering (no skipping layers): **UI → Controller → DAO interface → DatabaseManager → DB**.
UI never touches DAO or SQL. Controllers never touch Swing.

Interface files (`dao/*DAO.java`, `service/RouteCalculator.java`, `service/NotificationService.java`) are written ONCE by BACKEND and given to DATABASE. DATABASE implements them.

## 2. Project layout

```
SafePath/
├── db/schema.sql, db/seed.sql, db/db.properties
├── lib/ (JDBC driver jar)
└── src/com/safepath/
    ├── Main.java
    ├── model/       (Section 4)
    ├── dao/         (Section 6)
    ├── service/     (Section 7)
    ├── controller/  (Section 8)
    ├── exception/   (Section 9)
    ├── util/        (Section 10)
    └── ui/          (Section 11)
```

Root package: `com.safepath`. Every file starts with `package com.safepath.<sub>;`

## 3. Enums (package `com.safepath.model`) – exact values

```java
public enum UserRole        { PEDESTRIAN, ADMIN }
public enum RoutePreference { SAFEST, FASTEST, BALANCED }
public enum IncidentType    { THEFT, HARASSMENT, POOR_LIGHTING, DOG_THREAT, ACCIDENT, OTHER }
public enum Severity        { LOW(2), MEDIUM(5), HIGH(10);
                              private final int weight; Severity(int w){weight=w;}
                              public int getWeight(){return weight;} }
```

In the DB these are stored as the enum `name()` string (e.g. `'THEFT'`). Use `Enum.valueOf` / `.name()` to convert.

## 4. Model classes (package `com.safepath.model`)

All fields `private`, with public getters/setters named `getX / setX` (`isX` not used). Each class has a no-arg constructor AND a full constructor (all fields in the order listed). Each overrides `toString()`.
Dates: `java.time.LocalDateTime`. IDs: `int` (0 = not yet saved).

### User (abstract)
Fields: `int userId; String name; String email; String passwordHash;`
Methods: `abstract UserRole getRole();` `boolean login(String plainPassword)` (hashes with `PasswordUtil` and compares); `void logout()`; `void updateProfile(String name, String email)`.

### Pedestrian extends User
Extra field: `String phoneNo;` — `getRole()` returns `UserRole.PEDESTRIAN`.

### Admin extends User
No extra fields — `getRole()` returns `UserRole.ADMIN`.

### Location
`int locationId; String name; double latitude; double longitude;`

### Route
```
int routeId;
int sourceId;            // FK locations.location_id
int destinationId;       // FK locations.location_id
String name;
double distanceKm;
int estimatedTimeMin;
int lightingLevel;       // 1 (dark) .. 5 (well lit)
int crowdDensity;        // 1 (empty) .. 5 (busy)  -> busier = safer
int dogRisk;             // 1 (none)  .. 5 (high)
double safetyScore;      // 0..100, COMPUTED by BACKEND, not stored in DB
double avgRating;        // 0..5,   COMPUTED from feedback, not stored in DB
```

### Incident
`int incidentId; int routeId; int reporterId; IncidentType type; Severity severity; String description; LocalDateTime reportedAt;`

### Feedback
`int feedbackId; int routeId; int userId; int rating; String comments; LocalDateTime createdAt;`  (rating 1–5)

## 5. Database (owner: DATABASE) – exact names

Target: **MySQL 8** (`db name: safepath`). SQL must stay standard (no vendor-only features) so SQLite also works.

```sql
CREATE TABLE users (
  user_id       INT PRIMARY KEY AUTO_INCREMENT,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(128) NOT NULL,
  role          VARCHAR(15)  NOT NULL,          -- PEDESTRIAN | ADMIN
  phone_no      VARCHAR(20)
);
CREATE TABLE locations (
  location_id INT PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL UNIQUE,
  latitude    DOUBLE NOT NULL,
  longitude   DOUBLE NOT NULL
);
CREATE TABLE routes (
  route_id           INT PRIMARY KEY AUTO_INCREMENT,
  source_id          INT NOT NULL,
  destination_id     INT NOT NULL,
  name               VARCHAR(120) NOT NULL,
  distance_km        DOUBLE NOT NULL,
  estimated_time_min INT NOT NULL,
  lighting_level     INT NOT NULL,
  crowd_density      INT NOT NULL,
  dog_risk           INT NOT NULL,
  FOREIGN KEY (source_id)      REFERENCES locations(location_id),
  FOREIGN KEY (destination_id) REFERENCES locations(location_id)
);
CREATE TABLE incidents (
  incident_id INT PRIMARY KEY AUTO_INCREMENT,
  route_id    INT NOT NULL,
  reporter_id INT NOT NULL,
  type        VARCHAR(20) NOT NULL,
  severity    VARCHAR(10) NOT NULL,
  description VARCHAR(500),
  reported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id)    REFERENCES routes(route_id),
  FOREIGN KEY (reporter_id) REFERENCES users(user_id)
);
CREATE TABLE feedback (
  feedback_id INT PRIMARY KEY AUTO_INCREMENT,
  route_id    INT NOT NULL,
  user_id     INT NOT NULL,
  rating      INT NOT NULL,
  comments    VARCHAR(500),
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES routes(route_id),
  FOREIGN KEY (user_id)  REFERENCES users(user_id)
);
```

`seed.sql` must include: 1 admin (`admin@safepath.com`, password `admin123`, stored as SHA-256 hex via `PasswordUtil`), 1 test pedestrian (`test@safepath.com` / `test123`), at least 6 locations, at least 10 routes (several routes per source/destination pair so there is something to compare), a few incidents and feedback rows.

`db.properties` keys (fixed): `db.url`, `db.user`, `db.password`, `db.driver`.

## 6. DAO layer (package `com.safepath.dao`)

Interfaces are fixed. Implementations are named `<Name>DAOImpl`. All methods `throws DatabaseException` (unchecked wrapping is NOT allowed – use the checked exception from Section 9). Always use `PreparedStatement` and try-with-resources.

```java
public interface UserDAO {
    int  insert(User user) throws DatabaseException;            // returns generated id
    User findById(int userId) throws DatabaseException;         // null if none
    User findByEmail(String email) throws DatabaseException;    // null if none; returns Pedestrian or Admin by role
    List<User> findAll() throws DatabaseException;
    void update(User user) throws DatabaseException;
    void delete(int userId) throws DatabaseException;
}
public interface LocationDAO {
    int  insert(Location l) throws DatabaseException;
    Location findById(int id) throws DatabaseException;
    List<Location> findAll() throws DatabaseException;
    void update(Location l) throws DatabaseException;
    void delete(int id) throws DatabaseException;
}
public interface RouteDAO {
    int  insert(Route r) throws DatabaseException;
    Route findById(int id) throws DatabaseException;
    List<Route> findAll() throws DatabaseException;
    List<Route> findBySourceAndDestination(int sourceId, int destinationId) throws DatabaseException;
    void update(Route r) throws DatabaseException;
    void delete(int id) throws DatabaseException;
}
public interface IncidentDAO {
    int  insert(Incident i) throws DatabaseException;
    List<Incident> findAll() throws DatabaseException;
    List<Incident> findByRoute(int routeId) throws DatabaseException;
    List<Incident> findByRouteSince(int routeId, LocalDateTime since) throws DatabaseException;
    void delete(int incidentId) throws DatabaseException;
}
public interface FeedbackDAO {
    int  insert(Feedback f) throws DatabaseException;
    List<Feedback> findByRoute(int routeId) throws DatabaseException;
    double averageRatingForRoute(int routeId) throws DatabaseException;  // 0 if none
    List<Feedback> findAll() throws DatabaseException;
}
```

Implementations get connections ONLY via `DatabaseManager.getInstance().getConnection()`.

## 7. Service layer (package `com.safepath.service`)

```java
public interface RouteCalculator {
    /** Returns candidates sorted best-first; each Route has safetyScore filled. */
    List<Route> calculateRoute(Location source, Location destination, List<Route> candidates);
}
public class FastestCalculator  implements RouteCalculator { }   // sort by estimatedTimeMin ASC
public class SafestCalculator   implements RouteCalculator { }   // sort by safetyScore DESC
public class BalancedCalculator implements RouteCalculator { }   // see formula below

public class SafetyScoreCalculator {                              // THE ONLY place the formula lives
    public static double compute(Route route, List<Incident> incidentsLast30Days);
}

public interface NotificationService {
    void sendIncidentNotification(Incident incident, User reporter);
}
public class ConsoleNotificationService implements NotificationService { }  // prints/logs; Email/SMS simulated
```

### Safety score formula (0–100) – fixed
```
lightingPts = lightingLevel / 5.0 * 30
crowdPts    = crowdDensity  / 5.0 * 20
dogPts      = (6 - dogRisk) / 5.0 * 10
penalty     = min(40, sum of severity.getWeight() for incidents in last 30 days on this route)
safetyScore = clamp(lightingPts + crowdPts + dogPts + 40 - penalty, 0, 100)
```
Balanced: `score = 0.5 * (safetyScore/100) + 0.5 * (minTimeAmongCandidates / route.estimatedTimeMin)`, sorted DESC.

## 8. Controller layer (package `com.safepath.controller`)

Controllers receive plain values from UI, validate, call DAOs/services, and throw exceptions from Section 9. All public methods are `throws SafePathException`.

```java
public class AuthController {
    public Pedestrian register(String name, String email, String password, String phone) throws SafePathException;
    public User login(String email, String password) throws SafePathException;   // also sets SessionManager
    public void logout();
}
public class RouteController {
    public List<Location> getAllLocations() throws SafePathException;
    public List<Route> getRecommendedRoutes(int sourceId, int destinationId, RoutePreference pref) throws SafePathException;
    public Route getRouteDetails(int routeId) throws SafePathException;          // safetyScore + avgRating filled
}
public class IncidentController {
    public void reportIncident(int routeId, IncidentType type, Severity severity, String description) throws SafePathException;
        // uses SessionManager.getCurrentUser(); validates; IncidentDAO.insert; NotificationService
    public List<Incident> getIncidentsForRoute(int routeId) throws SafePathException;
}
public class FeedbackController {
    public void submitFeedback(int routeId, int rating, String comments) throws SafePathException;
    public List<Feedback> getFeedbackForRoute(int routeId) throws SafePathException;
}
public class AdminController {
    public List<User> getAllUsers() throws SafePathException;
    public void deleteUser(int userId) throws SafePathException;
    public List<Location> getAllLocations() throws SafePathException;
    public void addLocation(String name, double lat, double lng) throws SafePathException;
    public void updateLocation(Location l) throws SafePathException;
    public void deleteLocation(int locationId) throws SafePathException;
    public List<Route> getAllRoutes() throws SafePathException;
    public void addRoute(Route r) throws SafePathException;
    public void updateRoute(Route r) throws SafePathException;
    public void deleteRoute(int routeId) throws SafePathException;
    public List<Incident> getAllIncidents() throws SafePathException;
    public List<Feedback> getAllFeedback() throws SafePathException;
    public Map<String, Integer> getStatistics() throws SafePathException;
        // keys (fixed): "totalUsers","totalRoutes","totalLocations","totalIncidents","totalFeedback"
}
```
Each controller has a public no-arg constructor that creates its own DAO impls (`new UserDAOImpl()` etc.).

## 9. Exceptions (package `com.safepath.exception`)

```java
public class SafePathException    extends Exception          { public SafePathException(String msg){super(msg);}  public SafePathException(String msg, Throwable c){super(msg,c);} }
public class DatabaseException    extends SafePathException  { same two constructors }
public class AuthException        extends SafePathException  { same two constructors }   // bad login, duplicate email
public class ValidationException  extends SafePathException  { same two constructors }   // empty/invalid input
```
Messages must be user-readable (UI shows `e.getMessage()` in a JOptionPane).

## 10. Utilities (package `com.safepath.util`)

```java
public class DatabaseManager {                     // owner: DATABASE
    public static DatabaseManager getInstance();   // singleton, loads db/db.properties
    public Connection getConnection() throws DatabaseException;
    public void close();
}
public class PasswordUtil {                        // owner: BACKEND
    public static String hash(String plain);       // SHA-256, lowercase hex
}
public class SessionManager {                      // owner: BACKEND
    public static void setCurrentUser(User u);
    public static User getCurrentUser();           // null if not logged in
    public static boolean isAdmin();
    public static void clear();
}
public class Validator {                           // owner: BACKEND
    public static boolean isValidEmail(String s);
    public static boolean isNotBlank(String s);
    public static boolean isRatingValid(int r);    // 1..5
}
```

## 11. UI (package `com.safepath.ui`, owner: FRONTEND)

Class names are fixed so everyone can refer to them:
`LoginFrame`, `RegisterFrame`, `MainFrame` (pedestrian dashboard, tabbed), `RouteSearchPanel` (source/destination combos, preference radio buttons Safest/Fastest/Balanced), `RouteResultPanel` (table: name, distance, time, safety score, rating), `ReportIncidentDialog`, `FeedbackDialog`, `AdminFrame` (tabs) containing `ManageUsersPanel`, `ManageLocationsPanel`, `ManageRoutesPanel`, `ReportsPanel` (incidents, feedback, statistics).

Flow: `Main` → `LoginFrame` → (`PEDESTRIAN` → `MainFrame` | `ADMIN` → `AdminFrame`).
UI rules: catch `SafePathException` and show `JOptionPane.showMessageDialog(this, e.getMessage(), "Error", ERROR_MESSAGE)`. Run DB calls off the EDT only if needed; otherwise keep simple.

## 12. Naming conventions

Classes `PascalCase`; methods/fields `camelCase`; constants `UPPER_SNAKE`; DB tables/columns `snake_case` (exactly as Section 5); one public class per file, file name = class name.

## 13. Change process

1. Nobody edits the contract alone. Agree in the group chat, then one person edits this file and bumps the version (v1.1, v1.2 …).
2. Everyone re-pastes the new file into their AI.
3. Log below.

| Version | Change | Agreed by |
|---|---|---|
| v1.0 | Initial contract | all |

## 14. Integration checklist

- [ ] DATABASE: `schema.sql` + `seed.sql` run cleanly; `DatabaseManager.getConnection()` works
- [ ] BACKEND: models, enums, exceptions, DAO interfaces handed to DATABASE first (do this on day 1)
- [ ] DATABASE: all `*DAOImpl` compile against the interfaces
- [ ] BACKEND: controllers compile against DAOs; login/register works with seed data
- [ ] FRONTEND: every screen calls only controller methods listed in Section 8
- [ ] End-to-end: register → login → pick route (all 3 preferences) → report incident → feedback → admin views statistics
