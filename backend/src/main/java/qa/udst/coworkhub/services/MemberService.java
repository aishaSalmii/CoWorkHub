package qa.udst.coworkhub.services;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import qa.udst.coworkhub.exceptions.ConflictException;
import qa.udst.coworkhub.exceptions.ResourceNotFoundException;
import qa.udst.coworkhub.models.Booking;
import qa.udst.coworkhub.models.Member;
import qa.udst.coworkhub.repositories.BookingRepository;
import qa.udst.coworkhub.repositories.MemberRepository;

@Service 
public class MemberService {

    private final MemberRepository memberRepository;
    private final BookingRepository bookingRepository;

    public MemberService(MemberRepository memberRepository,BookingRepository bookingRepository){
        this.memberRepository = memberRepository;
        this.bookingRepository = bookingRepository;
    }

    public List<Member> findAll() {
        return memberRepository.findAll();
    }

    public Member findById(Long id) {
        return memberRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Member with id " + id + " was not found."));
    }

    @Transactional
    public Member create(Member member) {

        if (memberRepository.existsByEmail(member.getEmail())) {
            throw new ConflictException(
                    "A member with email " + member.getEmail()
                    + " already exists.");
        }

        member.setId(null);
        return memberRepository.save(member);
    }

    public List<Booking> findBookingsOfMember(Long memberId) {
        findById(memberId);
        return bookingRepository.findByMemberId(memberId);
    }

}
