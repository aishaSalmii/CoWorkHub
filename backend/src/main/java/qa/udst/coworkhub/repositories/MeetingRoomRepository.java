package qa.udst.coworkhub.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import qa.udst.coworkhub.models.MeetingRoom;

/**
 * Data access for meeting rooms only.
 * findAll() here returns only rows with resource_type = 'MEETING_ROOM'.
 */
public interface MeetingRoomRepository extends JpaRepository<MeetingRoom, Long> {
}