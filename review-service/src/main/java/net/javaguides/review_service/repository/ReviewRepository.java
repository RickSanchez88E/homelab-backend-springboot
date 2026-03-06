package net.javaguides.review_service.repository;

import net.javaguides.review_service.entity.Review;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReviewRepository extends JpaRepository<Review, String> {

    // 返回 Slice 而不是 Page → 不执行 COUNT(*)
    // Spring Data JPA 会自动多取1条来判断 hasNext
    Slice<Review> findAllBy(Pageable pageable);
}
