package qa.udst.coworkhub.models;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import lombok.Getter;
import lombok.Setter;

/**
 * A single desk. A desk is always for one person, so its capacity is 1.
 * Rows of this class have resource_type = 'DESK'.
 */
@Entity
@DiscriminatorValue("DESK")
@Getter
@Setter
public class Desk extends BookableResource {

    @Enumerated(EnumType.STRING)
    @Column(name = "desk_type", length = 20)
    private DeskType deskType = DeskType.HOT_DESK;

    /**
     * No-argument constructor required by JPA.
     * We write it ourselves (instead of @NoArgsConstructor)
     * so every new desk starts with capacity 1.
     */
    public Desk() {
        setCapacity(1);
    }

    @Override
    public String getResourceType() {
        return "DESK";
    }
}