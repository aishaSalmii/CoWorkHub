package qa.udst.coworkhub.controllers;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import qa.udst.coworkhub.models.BookableResource;
import qa.udst.coworkhub.models.Desk;
import qa.udst.coworkhub.models.MeetingRoom;
import qa.udst.coworkhub.services.ResourceService;

/**
 * REST endpoints for coworking resources.
 * Base URL: /api/resources
 */
@RestController
@RequestMapping("/api/resources")
public class ResourceController {

    private final ResourceService resourceService;

    public ResourceController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // GET /api/resources?type=DESK&minCapacity=2&location=floor&maxPrice=50
    @GetMapping
    public List<BookableResource> getAll(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) Integer minCapacity,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) BigDecimal maxPrice) {
        return resourceService.findAll(type, minCapacity, location, maxPrice);
    }

    // GET /api/resources/{id}
    @GetMapping("/{id}")
    public BookableResource getById(@PathVariable Long id) {
        return resourceService.findById(id);
    }

    // POST /api/resources/rooms
    @PostMapping("/rooms")
    public ResponseEntity<MeetingRoom> createRoom(@Valid @RequestBody MeetingRoom room) {
        MeetingRoom created = resourceService.createRoom(room);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // POST /api/resources/desks
    @PostMapping("/desks")
    public ResponseEntity<Desk> createDesk(@Valid @RequestBody Desk desk) {
        Desk created = resourceService.createDesk(desk);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT /api/resources/{id}/room
    @PutMapping("/{id}/room")
    public MeetingRoom updateRoom(@PathVariable Long id, @Valid @RequestBody MeetingRoom room) {
        return resourceService.updateRoom(id, room);
    }

    // PUT /api/resources/{id}/desk
    @PutMapping("/{id}/desk")
    public Desk updateDesk(@PathVariable Long id, @Valid @RequestBody Desk desk) {
        return resourceService.updateDesk(id, desk);
    }

    // DELETE /api/resources/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        resourceService.delete(id);
        return ResponseEntity.noContent().build();
    }
}