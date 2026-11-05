package qa.udst.coworkhub.dto;

import java.time.LocalDateTime;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * The JSON the client sends to create or update a booking.
 * The client only sends ids and times; the backend decides the status and the total cost.
 */
@Getter
@Setter
@NoArgsConstructor
public class BookingRequest {

    @NotNull(message = "Member id is required")
    private Long memberId;

    @NotNull(message = "Resource id is required")
    private Long resourceId;

    @NotNull(message = "Start date and time is required")
    private LocalDateTime startDateTime;

    @NotNull(message = "End date and time is required")
    private LocalDateTime endDateTime;

    @NotNull(message = "Number of attendees is required")
    @Min(value = 1, message = "Attendees must be at least 1")
    private Integer attendees;
}