package qa.udst.coworkhub.models;

/**
 * Operational status of a bookable resource.
 *
 * ACTIVE         - the resource can be booked.
 * OUT_OF_SERVICE - the resource is deactivated and cannot be booked,
 *                  but its booking history is kept.
 */
public enum ResourceStatus {
    ACTIVE,
    OUT_OF_SERVICE
}