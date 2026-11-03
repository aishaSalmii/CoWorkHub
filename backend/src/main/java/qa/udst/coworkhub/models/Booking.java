package qa.udst.coworkhub.models;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * A reservation of one resource (meeting room or desk) by one member
 * for a time interval.
 */
@Entity
@Table(name = "bookings")
@Getter
@Setter
@NoArgsConstructor
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "Start date and time is required")
    @Column(name = "start_date_time", nullable = false)
    private LocalDateTime startDateTime;

    @NotNull(message = "End date and time is required")
    @Column(name = "end_date_time", nullable = false)
    private LocalDateTime endDateTime;

    @NotNull(message = "Number of attendees is required")
    @Min(value = 1, message = "Attendees must be at least 1")
    @Column(nullable = false)
    private Integer attendees;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BookingStatus status = BookingStatus.CONFIRMED;

    @Column(name = "total_cost", precision = 10, scale = 2)
    private BigDecimal totalCost;

    // Many bookings belong to one member. The bookings table stores member_id.
    @ManyToOne
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    // Many bookings belong to one resource. The bookings table stores resource_id.
    @ManyToOne
    @JoinColumn(name = "resource_id", nullable = false)
    private BookableResource resource;
}