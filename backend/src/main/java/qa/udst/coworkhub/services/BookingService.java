package qa.udst.coworkhub.services;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import qa.udst.coworkhub.dto.BookingRequest;
import qa.udst.coworkhub.exceptions.BusinessRuleException;
import qa.udst.coworkhub.exceptions.ConflictException;
import qa.udst.coworkhub.exceptions.ResourceNotFoundException;
import qa.udst.coworkhub.models.BookableResource;
import qa.udst.coworkhub.models.Booking;
import qa.udst.coworkhub.models.BookingStatus;
import qa.udst.coworkhub.models.Desk;
import qa.udst.coworkhub.models.Member;
import qa.udst.coworkhub.models.ResourceStatus;
import qa.udst.coworkhub.repositories.BookableResourceRepository;
import qa.udst.coworkhub.repositories.BookingRepository;
import qa.udst.coworkhub.repositories.MemberRepository;

/**
 * Business logic for bookings: all booking rules are checked here.
 */
@Service
public class BookingService {

    private final BookingRepository bookingRepository;
    private final MemberRepository memberRepository;
    private final BookableResourceRepository resourceRepository;

    // Constructor injection: Spring passes in the repositories.
    public BookingService(BookingRepository bookingRepository,
                          MemberRepository memberRepository,
                          BookableResourceRepository resourceRepository) {
        this.bookingRepository = bookingRepository;
        this.memberRepository = memberRepository;
        this.resourceRepository = resourceRepository;
    }

    public List<Booking> findAll() {
        return bookingRepository.findAll();
    }

    public Booking findById(Long id) {
        return bookingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Booking with id " + id + " was not found."));
    }

    @Transactional
    public Booking create(BookingRequest request) {
        Member member = findMember(request.getMemberId());
        BookableResource resource = findResource(request.getResourceId());

        checkBookingRules(resource, request);

        // Rule 6: no overlapping CONFIRMED booking on the same resource
        boolean overlaps = bookingRepository
                .existsByResourceIdAndStatusAndStartDateTimeLessThanAndEndDateTimeGreaterThan(
                        resource.getId(), BookingStatus.CONFIRMED,
                        request.getEndDateTime(), request.getStartDateTime());
        if (overlaps) {
            throw new ConflictException("'" + resource.getName()
                    + "' is already booked during the selected time.");
        }

        Booking booking = new Booking();
        booking.setMember(member);
        booking.setResource(resource);
        booking.setStartDateTime(request.getStartDateTime());
        booking.setEndDateTime(request.getEndDateTime());
        booking.setAttendees(request.getAttendees());
        booking.setStatus(BookingStatus.CONFIRMED);                    // Rule 7: backend sets the status
        booking.setTotalCost(calculateTotalCost(resource, request));   // Rule 7: backend calculates the cost

        return bookingRepository.save(booking);
    }

    @Transactional
    public Booking update(Long id, BookingRequest request) {
        Booking booking = findById(id);

        // Rule 8: a cancelled booking cannot be changed
        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new BusinessRuleException("A cancelled booking cannot be updated.");
        }

        Member member = findMember(request.getMemberId());
        BookableResource resource = findResource(request.getResourceId());

        checkBookingRules(resource, request);

        // Rule 6 for updates: ignore the booking we are updating (IdNot)
        boolean overlaps = bookingRepository
                .existsByResourceIdAndStatusAndStartDateTimeLessThanAndEndDateTimeGreaterThanAndIdNot(
                        resource.getId(), BookingStatus.CONFIRMED,
                        request.getEndDateTime(), request.getStartDateTime(), id);
        if (overlaps) {
            throw new ConflictException("'" + resource.getName()
                    + "' is already booked during the selected time.");
        }

        booking.setMember(member);
        booking.setResource(resource);
        booking.setStartDateTime(request.getStartDateTime());
        booking.setEndDateTime(request.getEndDateTime());
        booking.setAttendees(request.getAttendees());
        booking.setTotalCost(calculateTotalCost(resource, request));

        return bookingRepository.save(booking);
    }

    /**
     * Cancels a booking by changing its status. The booking is never deleted,
     * so it stays in the history, and its time slot becomes free again.
     */
    @Transactional
    public Booking cancel(Long id) {
        Booking booking = findById(id);

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new BusinessRuleException("This booking is already cancelled.");
        }

        booking.setStatus(BookingStatus.CANCELLED);
        return bookingRepository.save(booking);
    }

    // ---------- helper methods ----------

    // Rule 1: the member must exist
    private Member findMember(Long memberId) {
        return memberRepository.findById(memberId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Member with id " + memberId + " was not found."));
    }

    // Rule 1: the resource must exist
    private BookableResource findResource(Long resourceId) {
        return resourceRepository.findById(resourceId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Resource with id " + resourceId + " was not found."));
    }

    // Rules 2 to 5
    private void checkBookingRules(BookableResource resource, BookingRequest request) {
        // Rule 2: the start must be before the end
        if (!request.getStartDateTime().isBefore(request.getEndDateTime())) {
            throw new BusinessRuleException("The start time must be before the end time.");
        }

        // Rule 3: an OUT_OF_SERVICE resource cannot be booked
        if (resource.getStatus() != ResourceStatus.ACTIVE) {
            throw new BusinessRuleException("'" + resource.getName()
                    + "' is out of service and cannot be booked.");
        }

        // Rule 4: a desk is for exactly one person
        if (resource instanceof Desk && request.getAttendees() != 1) {
            throw new BusinessRuleException("A desk can only be booked for 1 attendee.");
        }

        // Rule 5: attendees cannot exceed the capacity
        if (request.getAttendees() > resource.getCapacity()) {
            throw new BusinessRuleException("'" + resource.getName() + "' has a capacity of "
                    + resource.getCapacity() + ", but " + request.getAttendees()
                    + " attendees were requested.");
        }
    }

    // Rule 7: total cost = hourly rate x duration in hours (rounded to 2 decimals)
    private BigDecimal calculateTotalCost(BookableResource resource, BookingRequest request) {
        long minutes = Duration.between(request.getStartDateTime(), request.getEndDateTime()).toMinutes();
        return resource.getHourlyRate()
                .multiply(BigDecimal.valueOf(minutes))
                .divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP);
    }
}