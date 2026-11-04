package qa.udst.coworkhub.exceptions;

/**
 * Thrown when a request breaks a business rule,
 * for example the start time is after the end time,
 * or there are more attendees than the room capacity.
 *
 * The GlobalExceptionHandler turns it into HTTP 400 Bad Request.
 */
public class BusinessRuleException extends RuntimeException {

    public BusinessRuleException(String message) {
        super(message);
    }
}