package qa.udst.coworkhub.controllers;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import qa.udst.coworkhub.models.BookableResource;
import qa.udst.coworkhub.services.AvailabilityService;


@RestController 
@RequestMapping ("/api/resources")
public class AvailabilityController {

    private final AvailabilityService availabilityService;

    public AvailabilityController(AvailabilityService availabilityService){
        this.availabilityService=availabilityService;
    }

    @GetMapping ("/available")
    public List<BookableResource> getAvailable(
        @RequestParam (required = false)
        @DateTimeFormat (iso= DateTimeFormat.ISO.DATE_TIME)
        LocalDateTime start,
        @RequestParam (required = false)
        @DateTimeFormat (iso= DateTimeFormat.ISO.DATE_TIME)
        LocalDateTime end,
        @RequestParam(required = false)
        String type,
        @RequestParam (required = false)
        Integer minCapacity
    ){
        return availabilityService.findAvailable((start), end, type, minCapacity);
    }
}
