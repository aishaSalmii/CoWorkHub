# CoWorkHub

**INFS4102 Course Project — Coworking Space and Meeting Room Booking System**

## 1. Project Overview

CoWorkHub is a desktop application for managing a coworking space, including meeting rooms, desks, members, and bookings.

Users can browse and filter resources, check availability for a selected time interval, create bookings with automatic cost calculation, update or cancel bookings, and view booking history.

The backend validates booking operations and prevents invalid actions, including overlapping bookings, exceeding resource capacity, and booking out-of-service resources. The Flutter desktop application communicates with the backend through REST APIs and displays appropriate error messages.

## 2. Technology Stack

- **Frontend:** Flutter and Dart (desktop)
- **Backend:** Java 21 and Spring Boot 4.1.2
- **Build Tool:** Maven
- **Persistence:** Spring Data JPA and Hibernate
- **Database:** PostgreSQL 17
- **Communication:** REST API and JSON
- **Deployment:** Docker Compose
- **Version Control:** Git and GitHub

## 3. System Architecture

CoWorkHub follows a layered architecture:

```text
Flutter Desktop → REST Controller → Service → Repository → PostgreSQL
```

The Flutter desktop application runs on the host computer. Docker Compose runs the Spring Boot backend and PostgreSQL database.

For additional technical information:

- [System Architecture](docs/architecture.md)
- [REST API Documentation](docs/api.md)

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
├── backend/                  Spring Boot REST API
│   ├── Dockerfile            Multi-stage Java 21 Docker build
│   ├── pom.xml               Maven configuration
│   └── src/
│       ├── main/
│       └── test/
│
├── frontend/                 Flutter desktop application
│   ├── lib/
│   │   ├── models/           Resource, Member and Booking models
│   │   ├── screens/           Dashboard, Resources, Members and Bookings
│   │   ├── services/          API communication
│   │   ├── widgets/           Shared widgets and form dialogs
│   │   └── main.dart
│   ├── test/                  Flutter widget and service tests
│   └── pubspec.yaml
│
├── docs/
│   ├── api.md                 REST API documentation
│   └── architecture.md        System architecture
│
├── http/                      REST Client request files
│   ├── availability.http
│   ├── bookings.http
│   ├── demo-scenario.http
│   ├── members.http
│   └── resources.http
│
├── docker-compose.yml         Backend and PostgreSQL services
├── .env.example               Database password template
├── .gitignore
└── README.md
```

## 6. Requirements

Install the following tools before running the project:

| Tool | Purpose |
|---|---|
| Git | Clone and manage the repository |
| Docker Desktop | Run the backend and PostgreSQL database |
| Flutter SDK | Build and run the desktop application |
| Dart SDK | Included with Flutter |
| Visual Studio with Desktop development with C++ | Required for Windows desktop builds |

Java 21 and Maven are not required on the host computer when running the backend through Docker. The backend Dockerfile includes the Java 21 build and runtime environments.

For development without Docker, Java 21 is required.

Check your Flutter installation:

```bash
flutter doctor
```

## 7. Quick Start — Run Backend and Database with Docker

Follow these steps from the project root directory.

### Step 1 — Clone the repository

```bash
git clone https://github.com/aishaSalmii/CoWorkHub.git
cd CoWorkHub
```

### Step 2 — Configure the environment

Create a `.env` file from the provided template.

**Windows (PowerShell):**

```powershell
Copy-Item .env.example .env
```

**macOS / Linux:**

```bash
cp .env.example .env
```

Open `.env` and replace the placeholder with a local database password:

```text
DB_PASSWORD=choose_a_local_password
```

The `.env` file is ignored by Git. Never commit it or share your actual database password.

### Step 3 — Build and start the services

Make sure Docker Desktop is running.

From the CoWorkHub root directory, execute:

```bash
docker compose up --build -d
```

Docker Compose starts:

- PostgreSQL 17 database (`coworkhub-db`)
- Spring Boot backend (`coworkhub-backend`)

The first build may take a few minutes because Docker downloads Maven dependencies and builds the backend application.

### Step 4 — Verify the containers

Run:

```bash
docker compose ps
```

Check that:

- `coworkhub-db` is healthy.
- `coworkhub-backend` is running.

To view the backend startup logs:

```bash
docker compose logs -f backend
```

Wait until the logs display:

```text
Started CoworkhubApplication
```

### Step 5 — Check the REST API

Open the following address in a browser:

http://localhost:8080/api/resources

The API should return the available resources.

Sample resources and members are inserted automatically when the database is empty.

## 8. Run the Flutter Desktop Application

Make sure the Docker backend and database are running before launching Flutter.

Open a new terminal in the project root.

### Step 1 — Navigate to the frontend

```bash
cd frontend
```

### Step 2 — Install dependencies

```bash
flutter pub get
```

### Step 3 — Run the desktop application

**Windows:**

```bash
flutter run -d windows
```

**macOS:**

```bash
flutter run -d macos
```

**Linux:**

```bash
flutter run -d linux
```

The CoWorkHub desktop application should open and display the Dashboard.

The frontend communicates with the backend REST API at:

```text
http://localhost:8080/api
```

Keep Docker Compose running while using the application.

## 9. Run the Backend without Docker (Development)

This option is for developers who want to run Spring Boot directly on their computer.

First, start only the PostgreSQL database from the project root:

```bash
docker compose up -d db
```

Navigate to the backend directory:

```bash
cd backend
```

The application reads the database password from the `DB_PASSWORD` environment variable.

**Windows (PowerShell):**

```powershell
$env:DB_PASSWORD="your_password_from_env"
.\mvnw.cmd spring-boot:run
```

**macOS / Linux:**

From the project root, load the environment variables:

```bash
set -a
source .env
set +a
```

Then:

```bash
cd backend
./mvnw spring-boot:run
```

The backend runs on port `8080`.

Do not run the Docker backend and the local Spring Boot backend simultaneously because both use port `8080`.

If the Docker backend is running, stop it first from the project root:

```bash
docker compose stop backend
```

## 10. Configuration

The following environment variables configure the backend and database:

| Variable | Purpose | Default |
|---|---|---|
| `DB_PASSWORD` | PostgreSQL database password | Required in `.env` |
| `DB_URL` | Database connection URL | `jdbc:postgresql://localhost:5432/coworkhub` |
| `DB_USER` | Database username | `coworkhub_user` |

Docker Compose overrides the database URL for the backend container:

```text
jdbc:postgresql://db:5432/coworkhub
```

The database schema is managed through Hibernate using:

```properties
spring.jpa.hibernate.ddl-auto=update
```

Database data is stored in the Docker volume `coworkhub_data` and remains available after normal container restarts.

## 11. Stop the Application

To stop the Docker services, run this command from the project root:

```bash
docker compose down
```

This stops and removes the containers and network but preserves the database volume.

**Warning:** Do not use `docker compose down -v` unless you intentionally want to delete the database volume and all stored data.

## 12. Testing

### Flutter tests

From the project root:

```bash
cd frontend
flutter test
```

To check the Flutter code for issues:

```bash
flutter analyze
```

### Backend tests

The backend tests may require the PostgreSQL database to be running.

Start the database:

```bash
docker compose up -d db
```

Navigate to the backend directory:

```bash
cd backend
```

Run the Maven tests:

```bash
./mvnw test
```

On Windows PowerShell:

```powershell
.\mvnw.cmd test
```

### Manual API testing

The `http/` directory contains REST Client request files for testing the API.

Available files:

- `availability.http`
- `bookings.http`
- `members.http`
- `resources.http`
- `demo-scenario.http`

The demo scenario includes booking operations and an overlapping booking validation test.

## 13. Troubleshooting

| Problem | Possible solution |
|---|---|
| `The "DB_PASSWORD" variable is not set` | Create the `.env` file using `.env.example` and set `DB_PASSWORD`. |
| `password authentication failed for user "coworkhub_user"` | The database may have been initialized with a different password. The password in `.env` must match the database password. |
| Port `8080` already in use | Another backend may already be running. Stop the other backend or stop the Docker backend before running Spring Boot locally. |
| The app shows "Cannot reach the server" | Check that Docker is running and that the backend container is up. Use `docker compose ps` and `docker compose logs backend`. |
| PostgreSQL is not healthy | Check the database logs using `docker compose logs db` and verify the `.env` configuration. |
| Flutter dependencies are missing | Navigate to `frontend/` and run `flutter pub get`. |
| Windows desktop build fails | Check that Visual Studio with Desktop development with C++ is installed and run `flutter doctor`. |
| The frontend cannot connect to the backend | Confirm that the backend is running and that port `8080` is available. |

### Fixing a PostgreSQL password mismatch

If PostgreSQL was initialized with a different password, update the database user's password using the following command, replacing the placeholder with your actual local password:

```bash
docker exec -it coworkhub-db psql -U coworkhub_user -d coworkhub -c "ALTER USER coworkhub_user PASSWORD 'your_password_from_env';"
```

Then restart the backend:

```bash
docker compose restart backend
```

Do not share your actual password in screenshots or GitHub issues.

## 14. Development Workflow

The project uses Git and GitHub for version control and collaboration.

1. Create a GitHub Issue describing the task.
2. Create a separate branch for the change (`feature/...`, `fix/...`, or `docs/...`).
3. Implement and test the changes.
4. Commit and push the branch.
5. Create a Pull Request for review.
6. Merge the approved Pull Request into `main`.

## 15. Project Status

The CoWorkHub application includes:

- Flutter desktop frontend.
- Spring Boot REST API.
- PostgreSQL database integration.
- Resource and member management.
- Booking creation, editing and cancellation.
- Resource availability checking.
- Booking overlap and capacity validation.
- Automatic booking cost calculation.
- Dashboard statistics.
- Docker Compose deployment.
- Flutter automated tests and integration testing.

The project has undergone integration testing using the Windows desktop application with the Docker-based backend and PostgreSQL database.

## 16. Course Information

**Course:** INFS4102 — Desktop Application Development  
**Semester:** Fall 2026  
**University:** University of Doha for Science and Technology