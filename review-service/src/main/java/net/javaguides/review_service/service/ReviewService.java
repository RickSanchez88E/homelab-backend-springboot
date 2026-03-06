package net.javaguides.review_service.service;

import net.javaguides.review_service.dto.ReviewRequest;
import net.javaguides.review_service.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;

public interface ReviewService {
    Review create(ReviewRequest request);

    Review getById(String id);

    Page<Review> getAll(Pageable pageable);

    Slice<Review> getAllSlice(Pageable pageable); // 高性能版

    void deleteById(String id);
}
