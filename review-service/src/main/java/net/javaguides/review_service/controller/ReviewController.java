package net.javaguides.review_service.controller;

import lombok.RequiredArgsConstructor;
import net.javaguides.review_service.dto.ReviewRequest;
import net.javaguides.review_service.entity.Review;
import net.javaguides.review_service.service.ReviewService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @PostMapping
    public ResponseEntity<Review> create(@RequestBody ReviewRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(reviewService.create(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Review> getById(@PathVariable String id) {
        return ResponseEntity.ok(reviewService.getById(id));
    }

    /**
     * 高性能分页 — 用 Slice 代替 Page
     *
     * Page = SELECT * LIMIT 20 + SELECT COUNT(*) ← 慢！100万行要全表扫描
     * Slice = SELECT * LIMIT 21 ← 只多取1条判断有没有下一页，不做COUNT
     *
     * GET /api/v1/reviews?page=0&size=20
     */
    @GetMapping
    public ResponseEntity<Slice<Review>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        if (size > 100)
            size = 100;

        PageRequest pageRequest = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "createdAt"));

        return ResponseEntity.ok(reviewService.getAllSlice(pageRequest));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> delete(@PathVariable String id) {
        reviewService.deleteById(id);
        return ResponseEntity.ok("Deleted successfully");
    }
}
