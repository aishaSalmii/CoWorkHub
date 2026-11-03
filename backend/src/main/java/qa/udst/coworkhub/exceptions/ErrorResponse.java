package qa.udst.coworkhub.exceptions;

import java.time.LocalDateTime;

import lombok.Getter;

/**
 * The JSON body sent to the client whenever a request fails.
 *
 * Example:
 * {
 *   "status": 409,
 *   "error": "Conflict",
 *   "message": "This resource is already booked for the selected time.",
 *   "timestamp": "2026-11-10T09:15:30"
 * }
 */
@Getter
public class ErrorResponse {

    private final int status;
    private final String error;
    private final String message;
    private final LocalDateTime timestamp;

    public ErrorResponse(int status, String error, String message) {
        this.status = status;
        this.error = error;
        this.message = message;
        this.timestamp = LocalDateTime.now();
    }
}