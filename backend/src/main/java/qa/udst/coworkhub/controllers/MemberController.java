
package qa.udst.coworkhub.controllers;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import qa.udst.coworkhub.models.Booking;
import qa.udst.coworkhub.models.Member;
import qa.udst.coworkhub.services.MemberService;

@RestController
@RequestMapping("/api/members")
public class MemberController {

    private final MemberService memberService;

    public MemberController(MemberService memberService) {
        this.memberService = memberService;
    }

    // GET /api/members
    @GetMapping
    public List<Member> getAll() {
        return memberService.findAll();
    }

    // GET /api/members/{id}
    @GetMapping("/{id}")
    public Member getById(@PathVariable Long id) {
        return memberService.findById(id);
    }

    // POST /api/members
    @PostMapping
    public ResponseEntity<Member> create(@Valid @RequestBody Member member) {
        Member created = memberService.create(member);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT /api/members/{id}
    @PutMapping("/{id}")
    public Member update(@PathVariable Long id, @Valid @RequestBody Member member) {
        return memberService.update(id, member);
    }

    // GET /api/members/{id}/bookings
    @GetMapping("/{id}/bookings")
    public List<Booking> getBookings(@PathVariable Long id) {
        return memberService.findBookingsOfMember(id);
    }
}