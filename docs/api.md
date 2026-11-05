# CoWorkHub — REST API
Base URL: `http://localhost:8080/api`
All requests and responses use JSON. Dates use ISO format: `2026-12-01T10:00:00`.

# Resources
| Method | Endpoint | Description | Success | Errors |
|---|---|---|---|---|
| GET | `/resources` | List resources. Optional filters: `type`, `minCapacity`, `location`, `maxPrice` | 200 | 400 invalid type |
| GET | `/resources/{id}` | Get one resource | 200 | 404 |
| GET | `/resources/available?start=&end=` | Resources that are ACTIVE and have no overlapping CONFIRMED booking. Optional: `type`, `minCapacity` | 200 | 400 missing/invalid interval or type |
| POST | `/resources/rooms` | Create a meeting room | 201 | 400 validation |
| POST | `/resources/desks` | Create a desk | 201 | 400 validation |
| PUT | `/resources/{id}/room` | Update a meeting room | 200 | 400, 404 |
| PUT | `/resources/{id}/desk` | Update a desk | 200 | 400, 404 |
| DELETE | `/resources/{id}` | Delete a resource that has never been booked | 204 | 404, 409 |

# Members
| Method | Endpoint | Description | Success | Errors |
|---|---|---|---|---|
| GET | `/members` | List members | 200 | — |
| GET | `/members/{id}` | Get one member | 200 | 404 |
| POST | `/members` | Create a member | 201 | 400 validation, 409 duplicate email |
| GET | `/members/{id}/bookings` | Bookings of one member | 200 | 404 |

# Bookings
| Method | Endpoint | Description | Success | Errors |
|---|---|---|---|---|
| GET | `/bookings` | List all bookings | 200 | — |
| GET | `/bookings/{id}` | Get one booking | 200 | 404 |
| POST | `/bookings` | Create a booking | 201 | 400, 404, 409 overlap |
| PUT | `/bookings/{id}` | Update a booking | 200 | 400, 404, 409 overlap |
| PUT | `/bookings/{id}/cancel` | Cancel a booking | 200 | 400, 404 |


# Booking Request Body
```json
{
"memberId": 1,
"resourceId": 2,
"startDateTime": "2026-12-01T10:00:00",
"endDateTime": "2026-12-01T12:00:00",
"attendees": 4
}
```

# Booking Business Rules
| Rule | Error |
|---|---|
| Member and resource must exist | 404 |
| Start must be before end | 400 |
| Resource must be ACTIVE | 400 |
| A desk accommodates exactly 1 attendee | 400 |
| Attendees cannot exceed room capacity | 400 |
| No overlapping CONFIRMED booking on the same resource | 409 |
| Adjacent bookings are allowed | — |
| A cancelled booking cannot be updated or cancelled again | 400 |
| `totalCost = hourlyRate × duration` and status is set to CONFIRMED | — |


# Error Format
Every error returns JSON similar to:
```json
{
"status": 409,
"error": "Conflict",
"message": "'Demo Room' is already booked during the selected time.",
"timestamp": "2026-12-01T09:15:30"
}
```

# Status Codes
| Status | Meaning |
|---|---|
| 400 Bad Request | Invalid input or a broken business rule |
| 404 Not Found | The requested id does not exist |
| 409 Conflict | Overlapping booking, duplicate email, or deleting a resource with bookings |

# Testing
REST Client files in `http/`:
`resources.http`
`members.http`
`bookings.http`
`availability.http`
`demo-scenario.http`
