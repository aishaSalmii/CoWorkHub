package qa.udst.coworkhub.exceptions;

/**
 * Thrown when a request conflicts with data that already exists,
 * for example an overlapping booking, a duplicate email,
 * or deleting a resource that still has bookings.
 *
 * The GlobalExceptionHandler turns it into HTTP 409 Conflict.
 */
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}