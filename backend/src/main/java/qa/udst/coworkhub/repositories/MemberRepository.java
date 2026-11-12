package qa.udst.coworkhub.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import qa.udst.coworkhub.models.Member;

public interface MemberRepository extends JpaRepository<Member, Long>{
    
    boolean existsByEmail(String email);

    // true if ANOTHER member (different id) already uses this email
    boolean existsByEmailAndIdNot(String email, Long id);
}