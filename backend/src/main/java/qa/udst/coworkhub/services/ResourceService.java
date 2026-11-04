package qa.udst.coworkhub.services;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import qa.udst.coworkhub.exceptions.BusinessRuleException;
import qa.udst.coworkhub.exceptions.ConflictException;
import qa.udst.coworkhub.exceptions.ResourceNotFoundException;
import qa.udst.coworkhub.models.BookableResource;
import qa.udst.coworkhub.models.Desk;
import qa.udst.coworkhub.models.MeetingRoom;
import qa.udst.coworkhub.repositories.BookableResourceRepository;
import qa.udst.coworkhub.repositories.BookingRepository;
import qa.udst.coworkhub.repositories.DeskRepository;
import qa.udst.coworkhub.repositories.MeetingRoomRepository;

/**
 * Business logic for coworking resources (meeting rooms and desks).
 * The controller calls this class; this class calls the repositories.
 */
@Service
public class ResourceService {

    private final BookableResourceRepository resourceRepository;
    private final MeetingRoomRepository meetingRoomRepository;
    private final DeskRepository deskRepository;
    private final BookingRepository bookingRepository;

    // Constructor injection: Spring passes in the repositories.
    public ResourceService(BookableResourceRepository resourceRepository,
                           MeetingRoomRepository meetingRoomRepository,
                           DeskRepository deskRepository,
                           BookingRepository bookingRepository) {
        this.resourceRepository = resourceRepository;
        this.meetingRoomRepository = meetingRoomRepository;
        this.deskRepository = deskRepository;
        this.bookingRepository = bookingRepository;
    }

    /**
     * Returns all resources, optionally filtered.
     * Every filter is optional: a null value means "do not filter on this".
     */
    public List<BookableResource> findAll(String type, Integer minCapacity,
                                          String location, BigDecimal maxPrice) {
        validateType(type);

        return resourceRepository.findAll().stream()
                .filter(resource -> type == null
                        || resource.getResourceType().equalsIgnoreCase(type))
                .filter(resource -> minCapacity == null
                        || resource.getCapacity() >= minCapacity)
                .filter(resource -> location == null
                        || resource.getLocation().toLowerCase().contains(location.toLowerCase()))
                .filter(resource -> maxPrice == null
                        || resource.getHourlyRate().compareTo(maxPrice) <= 0)
                .toList();
    }

    public BookableResource findById(Long id) {
        return resourceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Resource with id " + id + " was not found."));
    }

    @Transactional
    public MeetingRoom createRoom(MeetingRoom room) {
        room.setId(null); // the database generates the id
        return meetingRoomRepository.save(room);
    }

    @Transactional
    public Desk createDesk(Desk desk) {
        desk.setId(null);    // the database generates the id
        desk.setCapacity(1); // a desk is always for one person
        return deskRepository.save(desk);
    }

    @Transactional
    public MeetingRoom updateRoom(Long id, MeetingRoom updated) {
        MeetingRoom existing = meetingRoomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Meeting room with id " + id + " was not found."));

        existing.setName(updated.getName());
        existing.setLocation(updated.getLocation());
        existing.setCapacity(updated.getCapacity());
        existing.setHourlyRate(updated.getHourlyRate());
        existing.setStatus(updated.getStatus());
        existing.setHasProjector(updated.getHasProjector());
        existing.setHasVideoConference(updated.getHasVideoConference());

        return meetingRoomRepository.save(existing);
    }

    @Transactional
    public Desk updateDesk(Long id, Desk updated) {
        Desk existing = deskRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Desk with id " + id + " was not found."));

        existing.setName(updated.getName());
        existing.setLocation(updated.getLocation());
        existing.setCapacity(1); // a desk is always for one person
        existing.setHourlyRate(updated.getHourlyRate());
        existing.setStatus(updated.getStatus());
        existing.setDeskType(updated.getDeskType());

        return deskRepository.save(existing);
    }

    /**
     * Deletes a resource only if it has never been booked.
     * Resources with bookings (even cancelled or past ones) must keep their history,
     * so they should be set to OUT_OF_SERVICE instead.
     */
    @Transactional
    public void delete(Long id) {
        BookableResource resource = findById(id); // throws 404 if it does not exist

        if (bookingRepository.existsByResourceId(id)) {
            throw new ConflictException("Resource '" + resource.getName()
                    + "' has bookings and cannot be deleted. Set its status to OUT_OF_SERVICE instead.");
        }

        resourceRepository.delete(resource);
    }

    /**
     * Checks that the type filter is MEETING_ROOM or DESK (or not given).
     */
    private void validateType(String type) {
        if (type != null
                && !type.equalsIgnoreCase("MEETING_ROOM")
                && !type.equalsIgnoreCase("DESK")) {
            throw new BusinessRuleException("Type must be MEETING_ROOM or DESK.");
        }
    }
}