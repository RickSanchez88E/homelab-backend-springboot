package net.javaguides.review_service.service.impl;

import lombok.RequiredArgsConstructor;
import net.javaguides.review_service.dto.ReviewRequest;
import net.javaguides.review_service.entity.Review;
import net.javaguides.review_service.repository.ReviewRepository;
import net.javaguides.review_service.service.ReviewService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;

    @Override
    public Review create(ReviewRequest request) {
        Review entity = new Review();
        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        return reviewRepository.save(entity);
    }

    @Override
    public Review getById(String id) {
        return reviewRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Review not found: " + id));
    }

    @Override
    public Page<Review> getAll(Pageable pageable) {
        return reviewRepository.findAll(pageable);
    }

    @Override
    public Slice<Review> getAllSlice(Pageable pageable) {
        // findAllBy 返回 Slice（不做 COUNT）
        // SQL 只有: SELECT * FROM reviews ORDER BY created_at DESC LIMIT 21
        return reviewRepository.findAllBy(pageable);
    }

    @Override
    public void deleteById(String id) {
        reviewRepository.deleteById(id);
    }
}
