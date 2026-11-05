package qa.udst.coworkhub.controllers;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import qa.udst.coworkhub.dto.BookingRequest;
import qa.udst.coworkhub.models.Booking;
import qa.udst.coworkhub.services.BookingService;

/**
 * REST endpoints for bookings.
 * Base URL: /api/bookings
 */
@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    // GET /api/bookings  -> all bookings (current and past, including cancelled)
    @GetMapping
    public List<Booking> getAll() {
        return bookingService.findAll();
    }

    // GET /api/bookings/{id}  -> one booking
    @GetMapping("/{id}")
    public Booking getById(@PathVariable Long id) {
        return bookingService.findById(id);
    }

    // POST /api/bookings  -> create a booking (201 Created)
    @PostMapping
    public ResponseEntity<Booking> create(@Valid @RequestBody BookingRequest request) {
        Booking created = bookingService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT /api/bookings/{id}  -> update a booking
    @PutMapping("/{id}")
    public Booking update(@PathVariable Long id, @Valid @RequestBody BookingRequest request) {
        return bookingService.update(id, request);
    }

    // PUT /api/bookings/{id}/cancel  -> cancel (status becomes CANCELLED, never deleted)
    @PutMapping("/{id}/cancel")
    public Booking cancel(@PathVariable Long id) {
        return bookingService.cancel(id);
    }
}