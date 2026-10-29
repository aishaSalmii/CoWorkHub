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

## 6. Development Status

The initial Spring Boot project has been generated, compiled, and started successfully. The PostgreSQL development environment and Docker configuration have been prepared.

JPA domain models, REST API functionality, Flutter integration, and final Docker deployment remain to be completed and tested.