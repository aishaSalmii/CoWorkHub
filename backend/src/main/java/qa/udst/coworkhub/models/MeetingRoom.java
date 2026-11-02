package qa.udst.coworkhub.models;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * A meeting room that can be booked by a group of attendees.
 * Rows of this class have resource_type = 'MEETING_ROOM'.
 */
@Entity
@DiscriminatorValue("MEETING_ROOM")
@Getter
@Setter
@NoArgsConstructor
public class MeetingRoom extends BookableResource {

    @Column(name = "has_projector")
    private Boolean hasProjector = false;

    @Column(name = "has_video_conference")
    private Boolean hasVideoConference = false;

    @Override
    public String getResourceType() {
        return "MEETING_ROOM";
    }
}