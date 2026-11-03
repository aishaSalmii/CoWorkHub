package qa.udst.coworkhub.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import qa.udst.coworkhub.models.Booking;

/**
 * Data access for bookings.
 */
public interface BookingRepository extends JpaRepository<Booking, Long> {

    // Display the bookings of a selected member.
    List<Booking> findByMemberId(Long memberId);

    // Check whether a resource has any bookings (a resource with bookings cannot be deleted).
    boolean existsByResourceId(Long resourceId);
}