package qa.udst.coworkhub.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import qa.udst.coworkhub.models.Desk;

/**
 * Data access for desks only.
 * findAll() here returns only rows with resource_type = 'DESK'.
 */
public interface DeskRepository extends JpaRepository<Desk, Long> {
}