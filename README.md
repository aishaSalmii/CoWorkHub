# CoWorkHub

**INFS4102 Course Project — Coworking Space and Meeting Room Booking System**

## 1. Project Overview

CoWorkHub is a desktop application for managing coworking spaces, meeting rooms, desks, members, and reservations.

The application will allow users to browse resources, check availability, create bookings, update or cancel reservations, and view booking history.

## 2. Technology Stack

- **Backend:** Java 21 and Spring Boot 4.1.2
- **Build Tool:** Maven
- **Database:** PostgreSQL
- **Persistence:** Spring Data JPA
- **Frontend:** Flutter and Dart
- **Communication:** REST API and JSON
- **Deployment:** Docker Compose
- **Version Control:** Git and GitHub

## 3. System Architecture

CoWorkHub follows a five-layer architecture:

Flutter Desktop → REST Controller → Service → Repository → PostgreSQL

For detailed documentation, see [System Architecture](docs/architecture.md).

## 4. Team Members

| Member | Responsibility |
|---|---|
| Aisha | Architecture, backend setup and database components |
| Areej | Booking business logic and REST APIs |
| Dana | Flutter desktop user interface |
| Ghada | Frontend-backend integration, Docker and testing |

All team members are responsible for understanding the complete application.

## 5. Project Structure

```text
CoWorkHub/
├── backend/
├── docs/
│   └── architecture.md
├── docker-compose.yml
├── .env.example
├── .gitignore
└── README.md
```

The `frontend/` folder will be added during Flutter development.

## 6. Development Environment Requirements

Before running the current backend setup, install:

- Java 21
- Maven or the included Maven wrapper
- Docker Desktop
- Git
- Visual Studio Code or another Java-compatible IDE

Flutter will also be required when frontend development begins.

## 7. Running the Development Backend

### Step 1 — Clone the repository

```bash
git clone https://github.com/aishaSalmii/CoWorkHub.git
cd CoWorkHub
```

Use the shared development branch until the setup Pull Request is merged into `main`.

### Step 2 — Configure the environment

Copy the environment example:

```bash
cp .env.example .env
```

Edit `.env` and replace the password placeholder with a local development password.

Never commit `.env` to GitHub.

### Step 3 — Start PostgreSQL

Make sure Docker Desktop is running.

From the project root:

```bash
docker compose up -d
docker compose ps
```

Confirm that the PostgreSQL database container is healthy.

### Step 4 — Load the database environment variable

On macOS/Linux, from the project root:

```bash
set -a
source .env
set +a
```

### Step 5 — Run Spring Boot

```bash
cd backend
./mvnw spring-boot:run
```

On Windows, use `.\mvnw.cmd spring-boot:run` and configure `DB_PASSWORD` in the Windows terminal environment.

The backend uses port `8080`.

### Step 6 — Stop the application

Press `Control + C` in the terminal running Spring Boot.

To stop the Docker services, run from the project root:

```bash
docker compose down
```

Do not use `docker compose down -v` unless you intentionally want to remove the database volume.

## 8. Current Development Status

**Completed:**
- Spring Boot backend project generated.
- Java and Maven configuration verified.
- Maven validation and compilation successful.
- Initial PostgreSQL Docker configuration created.
- Spring Boot application started successfully.
- Architecture documentation prepared.

**Still in development:**
- JPA entities, relationships and repositories.
- Resource and member management APIs.
- Booking management and business rules.
- Flutter desktop frontend.
- Frontend-backend integration.
- Complete backend and database Docker deployment.
- Automated integration tests and final report.

## 9. Development Workflow

Each team member works on a separate Git branch.

Changes are committed, pushed and submitted through GitHub Pull Requests for review before merging into `main`.

## 10. Course Information

**Course:** INFS4102 — Desktop Application Development  
**Semester:** Fall 2026  
**University:** University of Doha for Science and Technology