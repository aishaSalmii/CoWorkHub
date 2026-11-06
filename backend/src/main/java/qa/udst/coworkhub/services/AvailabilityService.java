package qa.udst.coworkhub.services;


import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import qa.udst.coworkhub.exceptions.BusinessRuleException;
import qa.udst.coworkhub.models.BookableResource;
import qa.udst.coworkhub.models.BookingStatus;
import qa.udst.coworkhub.models.ResourceStatus;
import qa.udst.coworkhub.repositories.BookableResourceRepository;
import qa.udst.coworkhub.repositories.BookingRepository;

@Service 
public class AvailabilityService{
    private final BookableResourceRepository resourceRepository;
    private final BookingRepository bookingRepository;
    public AvailabilityService(BookableResourceRepository resourceRepository,BookingRepository bookingRepository){
        this.resourceRepository=resourceRepository;
        this.bookingRepository=bookingRepository;
    }
    public List<BookableResource> findAvailable(LocalDateTime start,LocalDateTime end, String type, Integer minCapacity ){
        if(start==null || end==null){
            throw new BusinessRuleException("Both start and end date and time are required.");
        }
        if(!start.isBefore(end)){
            throw new BusinessRuleException("The start time must be before the end time.");
        }
        if(type != null 
            && !type.equalsIgnoreCase("MEETING_ROOM")
            && !type.equalsIgnoreCase("DESK")){
               throw new BusinessRuleException("Type must be MEETING_ROOM or DESK.");
            }
            return resourceRepository.findByStatus(ResourceStatus.ACTIVE)
            .stream()
            .filter(resource -> type ==null ||resource.getResourceType().equalsIgnoreCase(type))
            .filter(resource -> minCapacity==null || resource.getCapacity()>=minCapacity)
            .filter(resource -> !bookingRepository.existsByResourceIdAndStatusAndStartDateTimeLessThanAndEndDateTimeGreaterThan(
                resource.getId(),
                BookingStatus.CONFIRMED,
                end,
                start)).toList();
    }
}