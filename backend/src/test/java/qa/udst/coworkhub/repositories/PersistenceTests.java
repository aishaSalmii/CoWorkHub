package qa.udst.coworkhub.repositories;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import jakarta.transaction.Transactional;
import qa.udst.coworkhub.models.Booking;
import qa.udst.coworkhub.models.BookingStatus;
import qa.udst.coworkhub.models.MeetingRoom;
import qa.udst.coworkhub.models.Member;
import qa.udst.coworkhub.models.ResourceStatus;

@SpringBootTest 
@Transactional 
class PersistenceTests{


    @Autowired 
    private MemberRepository memberRepository;
    @Autowired 
     private BookableResourceRepository resourceRepository;
    @Autowired 
    private BookingRepository bookingRepository;

    @Test 
    void saveAndReadsBackMemberRoomAndBooking(){
        Member member = new Member();
        member.setFullName("Test Member");
        member.setEmail("test.member@coworkhub.test");
        member.setPhoneNumber("55599999");
        memberRepository.save(member);

        MeetingRoom room = new MeetingRoom();
        room.setName("Test Room");
        room.setLocation("Test Flooe");
        room.setCapacity(6);
        room.setHourlyRate(new BigDecimal("59.00"));
        resourceRepository.save(room);

        Booking booking = new Booking();
        booking.setMember(member);
        booking.setResource(room);
        booking.setStartDateTime(LocalDateTime.of(2026,12,1,9,0));
        booking.setEndDateTime(LocalDateTime.of(2026,12,1,11,0));
        booking.setAttendees(4);
        booking.setTotalCost(new BigDecimal("100.00"));
        bookingRepository.save(booking);

        assertNotNull(member.getId());
        assertNotNull(room.getId());
        assertNotNull(booking.getId());

        Booking saved = bookingRepository.findById(booking.getId()).orElseThrow();
        assertEquals(BookingStatus.CONFIRMED, saved.getStatus());
        assertEquals(4, saved.getAttendees());
        assertEquals("Test Member", saved.getMember().getFullName());
        assertEquals("Test Room", saved.getResource().getName());
        assertEquals("MEETING_ROOM", saved.getResource().getResourceType());
        assertEquals(ResourceStatus.ACTIVE, saved.getResource().getStatus());
    }

    @Test 
    void derivedQueriesFindBookingByMemberAndResource(){

        Member member = new Member();
        member.setFullName("Query Member");
        member.setEmail("query.member@coworkhub.test");
        member.setPhoneNumber("55588888");
        memberRepository.save(member);

        MeetingRoom room = new MeetingRoom();
        room.setName("Query Room");
        room.setLocation("Test Floor");
        room.setCapacity(4);
        room.setHourlyRate(new BigDecimal("30.00"));
        resourceRepository.save(room);


        MeetingRoom emptyRoom = new MeetingRoom();
        emptyRoom.setName("Empty Room");
        emptyRoom.setLocation("Test Floor");
        emptyRoom.setCapacity(4);
        emptyRoom.setHourlyRate(new BigDecimal("30.00"));
        resourceRepository.save(emptyRoom);

        Booking booking = new Booking();
        booking.setMember(member);
        booking.setResource(room);
        booking.setStartDateTime(LocalDateTime.of(2026,12,2,13,0));
        booking.setEndDateTime(LocalDateTime.of(2026,12,2,14,0));
        booking.setAttendees(2);
        bookingRepository.save(booking);

        List<Booking> memberBookings = bookingRepository.findByMemberId(member.getId());
        assertEquals(1, memberBookings.size());
        assertTrue(bookingRepository.existsByResourceId(room.getId()));
        assertFalse(bookingRepository.existsByResourceId(emptyRoom.getId()));
    }
}