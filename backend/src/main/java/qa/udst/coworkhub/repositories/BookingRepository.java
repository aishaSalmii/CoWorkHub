package qa.udst.coworkhub.repositories;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import qa.udst.coworkhub.models.Booking;
import qa.udst.coworkhub.models.BookingStatus;

/**
 * Data access for bookings.
 */
public interface BookingRepository extends JpaRepository<Booking, Long> {

    // Display the bookings of a selected member.
    List<Booking> findByMemberId(Long memberId);

    // Check whether a resource has any bookings (a resource with bookings cannot be deleted).
    boolean existsByResourceId(Long resourceId);

    // Overlap check for a NEW booking:
    // existing.start < newEnd AND existing.end > newStart (only CONFIRMED bookings)
    boolean existsByResourceIdAndStatusAndStartDateTimeLessThanAndEndDateTimeGreaterThan(
            Long resourceId, BookingStatus status, LocalDateTime newEnd, LocalDateTime newStart);

    // Same overlap check for an UPDATE, ignoring the booking being updated (IdNot).
    boolean existsByResourceIdAndStatusAndStartDateTimeLessThanAndEndDateTimeGreaterThanAndIdNot(
            Long resourceId, BookingStatus status, LocalDateTime newEnd, LocalDateTime newStart,
            Long bookingId);
}