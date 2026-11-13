# CoWorkHub — System Architecture

## 1. Project Overview

CoWorkHub is a desktop application for managing meeting room and desk bookings in a coworking space.

The system allows users to view available resources, manage members, create reservations, and track booking information.

## 2. Architecture

CoWorkHub follows a five-layer architecture:

1. **Flutter Desktop:** Provides the user interface, navigation, forms, and booking screens.
2. **REST Controller:** Receives HTTP requests from Flutter and returns JSON responses.
3. **Service:** Implements business rules such as booking validation, availability checking, and pricing.
4. **Repository:** Uses Spring Data JPA to access and manage database records.
5. **Relational Database:** Uses PostgreSQL to store resources, members, and bookings.

### Request Flow

Flutter Desktop → REST Controller → Service → Repository → PostgreSQL

Responses return through the same layers to the Flutter desktop client.

## 3. Technology Stack

| Component | Technology |
|---|---|
| Backend | Java 21, Spring Boot 4.1.2 |
| Build Tool | Maven |
| Persistence | Spring Data JPA |
| Database | PostgreSQL |
| Frontend | Flutter and Dart |
| Communication | REST API and JSON |
| Deployment | Docker Compose |
| Version Control | Git and GitHub |

## 4. Design Decisions

- **Spring Boot:** Used to develop the REST API and organize backend logic.
- **Spring Data JPA:** Used for relational database access and entity relationships.
- **PostgreSQL:** Selected as the relational database for persistent storage.
- **Flutter:** Used to develop the cross-platform desktop client.
- **REST/JSON:** Used for communication between frontend and backend.
- **Docker Compose:** Used to provide a reproducible backend and database environment.

## 5. Team Responsibilities

| Member | Responsibility |
|---|---|
| Aisha | Initial architecture/setup and backend database components |
| Areej | Booking business logic and REST operations |
| Dana | Flutter desktop interface |
| Ghada | API integration, Docker deployment and testing |

All team members are responsible for understanding the complete application.

## 6. Deployment Architecture (Docker)

The server side runs in Docker Compose. The Flutter desktop client runs natively on the host machine.

```text
Host machine                         Docker Compose
┌──────────────────┐   HTTP/JSON    ┌───────────────────────────┐      JDBC       ┌──────────────────────┐
│ Flutter Desktop  │ ─────────────► │ backend  (Spring Boot)    │ ──────────────► │ db  (PostgreSQL 17)  │
│ localhost:8080   │                │ container port 8080       │  db:5432        │ volume coworkhub_data│
└──────────────────┘                └───────────────────────────┘                 └──────────────────────┘
```

| Item | Details |
|---|---|
| Start command | `docker compose up --build` (from the project root) |
| `db` service | `postgres:17`, healthcheck with `pg_isready`, data stored in the named volume `coworkhub_data` |
| `backend` service | Built from `backend/Dockerfile`; starts only after `db` is healthy (`depends_on: condition: service_healthy`) |
| Multi-stage Dockerfile | Stage 1 (`maven:3.9-eclipse-temurin-21`) builds the JAR from `pom.xml` and `src/`; stage 2 (`eclipse-temurin:21-jre`) runs only the JAR. The build does not depend on `backend/target/` |
| Configuration | Environment variables: `DB_URL` (inside Docker the host is the service name `db`), `DB_USER`, `DB_PASSWORD`. `application.properties` uses defaults for local development, e.g. `${DB_URL:jdbc:postgresql://localhost:5432/coworkhub}` |
| Secrets | `DB_PASSWORD` comes from a local `.env` file, which is ignored by Git; `.env.example` contains only a placeholder |
| Schema strategy | `spring.jpa.hibernate.ddl-auto=update`: non-destructive, so data is kept across restarts (`create`/`create-drop` are not used) |
| Sample data | `DataSeeder` inserts sample resources and members only when the tables are empty |

## 7. Domain Model — Resource Inheritance

`BookableResource` is an abstract JPA entity with two subclasses: `MeetingRoom` and `Desk`.

**Chosen strategy: `SINGLE_TABLE`** (table `bookable_resources`, discriminator column `resource_type` with values `MEETING_ROOM` / `DESK`).

| Strategy | Why it was or was not chosen |
|---|---|
| **SINGLE_TABLE (chosen)** | The hierarchy is small (two subclasses with only one or two extra fields each). The most frequent queries — listing resources, filtering, and availability search — read rooms and desks together, which needs no joins. Bookings reference one resource table through a single foreign key. |
| JOINED | Fully normalised, but every resource read would need a join between the base table and a subclass table, adding complexity without benefit for so few subclass fields. |
| TABLE_PER_CLASS | Listing all resources would require a UNION of two tables, and a booking foreign key could not point to one resource table. |

**Trade-off accepted:** subclass columns (`has_projector`, `has_video_conference`, `desk_type`) are nullable, because they are empty for the other resource type. For this reason they use wrapper types (`Boolean`) instead of primitives.

**Other design choices**
- `hourlyRate` uses `BigDecimal` to avoid rounding errors in prices.
- Enums are stored with `@Enumerated(EnumType.STRING)` so the database contains readable values and reordering the enum cannot corrupt data.
- A `Desk` always starts with capacity 1, because a desk accommodates one person.
- Repositories: `BookableResourceRepository` (all resources, with the derived query `findByStatus` used by the availability search), `MeetingRoomRepository` and `DeskRepository` (used to create and update each resource type). Filtering by capacity, location and price is done in `ResourceService`.

## 8. Entity Relationships

| Relationship | Mapping |
|---|---|
| A `Booking` belongs to one `Member` | `@ManyToOne` + `@JoinColumn(name = "member_id", nullable = false)` |
| A `Booking` is for one `BookableResource` | `@ManyToOne` + `@JoinColumn(name = "resource_id", nullable = false)` |
| A `Member` has many bookings | `@OneToMany(mappedBy = "member")` |
| A `BookableResource` has many bookings | `@OneToMany(mappedBy = "resource")` |

`Booking` is the owning side (it holds the foreign keys). The `@OneToMany` lists are marked `@JsonIgnore` so that JSON responses do not loop (booking → member → bookings → …). A member's bookings are returned by the endpoint `GET /api/members/{id}/bookings`.

## 9. Business Rules and Error Handling

Business rules are checked in the service layer (`BookingService`, `ResourceService`, `MemberService`), never in the controllers or the Flutter client alone.

- A booking's start must be before its end; attendees must fit the resource (a desk takes exactly 1 person).
- Only `ACTIVE` resources can be booked.
- Two `CONFIRMED` bookings on the same resource may not overlap: `existingStart < newEnd AND existingEnd > newStart`. Adjacent bookings are allowed, and `CANCELLED` bookings do not block a time slot.
- `totalCost = hourlyRate × duration in hours`, rounded to 2 decimals.

Errors are thrown as custom exceptions and converted to JSON by `GlobalExceptionHandler` (`@RestControllerAdvice`):

| Exception | HTTP status |
|---|---|
| `ResourceNotFoundException` | 404 Not Found |
| `BusinessRuleException` | 400 Bad Request |
| `ConflictException` (overlap, duplicate email, resource with bookings) | 409 Conflict |
| Bean Validation errors, unreadable JSON, wrong parameter types | 400 Bad Request |

Every error uses the same body: `{"status", "error", "message", "timestamp"}`. The Flutter client shows the `message` to the user.

## 10. Flutter Client Structure

| Folder | Contents |
|---|---|
| `lib/models/` | `Resource`, `Member`, `Booking` with `fromJson` / `toJson` |
| `lib/services/` | `ApiService`, the only class that sends HTTP requests; errors become an `ApiException` with the backend message |
| `lib/screens/` | Dashboard, Resources, New Booking, Bookings, Members |
| `lib/widgets/` | Reusable widgets: `LoadingView`, `ErrorView`, member and resource form dialogs |

Screens call `ApiService` with `async`/`await`, show loading and error states (with Retry), validate forms before sending, and reload their data after a successful create, update or cancel. Navigation uses a `NavigationRail`. Each screen accepts an optional `ApiService`, so widget tests can replace the backend with a fake (`MockClient`).