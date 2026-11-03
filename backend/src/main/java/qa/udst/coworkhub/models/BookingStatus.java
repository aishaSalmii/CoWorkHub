package qa.udst.coworkhub.models;

/**
 * Status of a booking.
 *
 * CONFIRMED - the booking is active and blocks the time slot.
 * CANCELLED - the booking was cancelled; it no longer blocks the time slot,
 *             but it stays in the database as history.
 */
public enum BookingStatus {
    CONFIRMED,
    CANCELLED
}