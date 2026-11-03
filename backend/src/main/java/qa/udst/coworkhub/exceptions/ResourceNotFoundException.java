package qa.udst.coworkhub.exceptions;

/**
 * Thrown when a requested record does not exist,
 * for example a member, resource or booking with an unknown id.
 *
 * The GlobalExceptionHandler turns it into HTTP 404 Not Found.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}