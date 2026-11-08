package qa.udst.coworkhub.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import qa.udst.coworkhub.models.BookableResource;
import qa.udst.coworkhub.models.ResourceStatus;

/**
 * Data access for all resources (meeting rooms and desks together).
 * JpaRepository already provides save, findById, findAll, existsById, deleteById, count ...
 */
public interface BookableResourceRepository extends JpaRepository<BookableResource, Long> {

    // Availability search: only ACTIVE resources can be booked.
    List<BookableResource> findByStatus(ResourceStatus status);
}