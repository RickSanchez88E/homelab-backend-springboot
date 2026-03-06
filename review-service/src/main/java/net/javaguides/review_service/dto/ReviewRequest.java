package net.javaguides.review_service.dto;

import lombok.Data;

@Data
public class ReviewRequest {
    // TODO: 添加前端传入的字段（不包含 id 和 createdAt）
    private String name;
    private String description;
}
