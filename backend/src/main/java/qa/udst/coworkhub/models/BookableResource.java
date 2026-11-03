package qa.udst.coworkhub.models;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorColumn;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Parent entity for everything that can be booked (meeting rooms and desks).
 *
 * Inheritance strategy: SINGLE_TABLE.
 * All resources are stored in one table "bookable_resources".
 * The column "resource_type" tells JPA whether a row is a MEETING_ROOM or a DESK.
 */
@Entity
@Table(name = "bookable_resources")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "resource_type")
@Getter
@Setter
@NoArgsConstructor
public abstract class BookableResource {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Name is required")
    @Column(nullable = false)
    private String name;

    @NotBlank(message = "Location is required")
    @Column(nullable = false)
    private String location;

    @NotNull(message = "Capacity is required")
    @Min(value = 1, message = "Capacity must be at least 1")
    @Column(nullable = false)
    private Integer capacity;

    @NotNull(message = "Hourly rate is required")
    @Positive(message = "Hourly rate must be greater than 0")
    @Column(name = "hourly_rate", nullable = false, precision = 10, scale = 2)
    private BigDecimal hourlyRate;

    @NotNull(message = "Status is required")
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    // One resource can have many bookings. "resource" is the field name in Booking.
    @OneToMany(mappedBy = "resource")
    @JsonIgnore
    private List<Booking> bookings = new ArrayList<>();
    private ResourceStatus status = ResourceStatus.ACTIVE;

    /**
     * Returns "MEETING_ROOM" or "DESK".
     * This is not stored as a separate field; each subclass returns its own value.
     * Jackson includes it in the JSON so the Flutter client can tell the types apart.
     */
    public abstract String getResourceType();
}