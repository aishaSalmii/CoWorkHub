package qa.udst.coworkhub.config;

import java.math.BigDecimal;
import org.springframework.stereotype.Component;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;

import qa.udst.coworkhub.models.Desk;
import qa.udst.coworkhub.models.DeskType;
import qa.udst.coworkhub.models.MeetingRoom;
import qa.udst.coworkhub.models.Member;
import qa.udst.coworkhub.repositories.BookableResourceRepository;
import qa.udst.coworkhub.repositories.MemberRepository;

@Component 
public class DataSeeder implements CommandLineRunner {
    
    private static  final Logger log = LoggerFactory.getLogger(DataSeeder.class);
    private final BookableResourceRepository resourceRepository;
    private final MemberRepository memberRepository;
    public DataSeeder(BookableResourceRepository resourceRepository,MemberRepository memberRepository){
        this.resourceRepository=resourceRepository;
        this.memberRepository=memberRepository;
    
    }
    @Override 
    public void run(String... args){
        seedResources();
        seedMembers();

    }
    private void seedResources(){
        if(resourceRepository.count()>0){
            log.info("Resources already exist -skipping sample resources");
            return;
        }
        MeetingRoom boardroom = new MeetingRoom();
        boardroom.setName("Boardroom");
        boardroom.setLocation("Floor 2");
        boardroom.setCapacity(10);
        boardroom.setHourlyRate(new BigDecimal("80.00"));
        boardroom.setHasProjector(true);
        boardroom.setHasVideoConference(true);

        MeetingRoom focusRoom = new MeetingRoom();
        focusRoom.setName("focus Room");
        focusRoom.setLocation("Floor 1");
        focusRoom.setCapacity(4);
        focusRoom.setHourlyRate(new BigDecimal("40.00"));
        focusRoom.setHasProjector(false);
        focusRoom.setHasVideoConference(true);

        Desk hotDesk = new Desk();
        hotDesk.setName("Hot Desk A1");
        hotDesk.setLocation("Floor 1");
        hotDesk.setHourlyRate(new BigDecimal("10.00"));
        hotDesk.setDeskType(DeskType.HOT_DESK);

        Desk StandingDesk = new Desk();
        StandingDesk.setName("Standing Desk B1");
        StandingDesk.setLocation("Floor 2");
        StandingDesk.setHourlyRate(new BigDecimal("12.50"));
        StandingDesk.setDeskType(DeskType.HOT_DESK);
 
        resourceRepository.save(boardroom);
        resourceRepository.save(focusRoom);
        resourceRepository.save(hotDesk);
        resourceRepository.save(StandingDesk);

        log.info("Inserted 4 sample resources");
    }
 
    private void seedMembers(){
        if(memberRepository.count()>0){
            log.info("Members already exist -skipping sample members");
            return;
        }
        Member sara = new Member();
        sara.setFullName("Sara ahmed");
        sara.setEmail("sara.ahmed@example.com");
        sara.setPhoneNumber("55510001");

        Member omar = new Member();
        omar.setFullName("omar khalid");
        omar.setEmail("omar.khalid@example.com");
        omar.setPhoneNumber("55510002");

        memberRepository.save(sara);
        memberRepository.save(omar);

       log.info("Inserted 2 sample members");
       




    }

}