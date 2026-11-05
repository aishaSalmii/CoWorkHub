package qa.udst.coworkhub.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import qa.udst.coworkhub.models.Member;

public interface MemberRepository extends JpaRepository<Member, Long>{
    
    boolean existsByEmail(String email);
}
