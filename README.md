# 🚀 Spring Boot Kafka Microservices — 全栈后端实战学习库

> 本项目是一个基于 **Spring Boot 3.x + Apache Kafka + Docker** 的微服务电商系统完整实践，涵盖 Java 后端工程师面试中最高频的核心知识点。从零开始，边做边学。

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.3-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Kafka](https://img.shields.io/badge/Apache%20Kafka-3.x-black.svg)](https://kafka.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![MySQL](https://img.shields.io/badge/MySQL-8.x-blue.svg)](https://www.mysql.com/)

---

## 📋 目录

1. [项目架构总览](#-项目架构总览)
2. [技术栈一览](#-技术栈一览)
3. [快速启动](#-快速启动)
4. [模块详解](#-模块详解)
5. [🎯 面试考点一：微服务架构设计](#-面试考点一微服务架构设计)
6. [🎯 面试考点二：Spring Boot 核心](#-面试考点二spring-boot-核心)
7. [🎯 面试考点三：Apache Kafka 消息队列](#-面试考点三apache-kafka-消息队列)
8. [🎯 面试考点四：Spring Security + JWT](#-面试考点四spring-security--jwt)
9. [🎯 面试考点五：数据库与JPA](#-面试考点五数据库与jpa)
10. [🎯 面试考点六：Redis 缓存](#-面试考点六redis-缓存)
11. [🎯 面试考点七：API Gateway & 服务发现](#-面试考点七api-gateway--服务发现)
12. [🎯 面试考点八：分布式事务与一致性](#-面试考点八分布式事务与一致性)
13. [🎯 面试考点九：Docker 容器化](#-面试考点九docker-容器化)
14. [🎯 面试考点十：可观测性与调用链追踪](#-面试考点十可观测性与调用链追踪)
15. [🎯 面试考点十一：设计模式实战](#-面试考点十一设计模式实战)
16. [🎯 面试考点十二：并发与性能](#-面试考点十二并发与性能)
17. [项目实践路线图](#-项目实践路线图)

---

## 📐 项目架构总览

```
                         ┌─────────────────────────────────────────┐
                         │           API Gateway (8080)            │
                         │    Spring Cloud Gateway + JWT Filter     │
                         └──────────────┬──────────────────────────┘
                                        │ 路由转发
              ┌─────────────────────────┼────────────────────────┐
              │                         │                        │
   ┌──────────▼──────┐      ┌──────────▼──────┐     ┌──────────▼──────┐
   │  Order Service  │      │ Product Service │     │Identity Service │
   │    (8082)       │      │    (8081)       │     │    (8085)       │
   └──────┬──────────┘      └──────┬──────────┘     └─────────────────┘
          │                        │
          │ Kafka Events           │ Kafka Events
          ▼                        ▼
   ┌──────────────────────────────────────────┐
   │          Apache Kafka (9092)             │
   │    Topics: order-events, payment-events  │
   └──────┬────────────────────┬─────────────┘
          │                    │
   ┌──────▼──────┐     ┌──────▼──────┐
   │Payment Svc  │     │ Email Svc   │
   │   (8083)    │     │   (8084)    │
   └─────────────┘     └─────────────┘

   ┌──────────────────────────────────────────┐
   │       Eureka Server (8761)               │
   │       Service Registry & Discovery       │
   └──────────────────────────────────────────┘

   Infrastructure: MySQL × 4 | Redis | Zookeeper
```

### 数据流示例（下单流程）

```
用户 → API Gateway (验证JWT) → Order Service (创建订单)
  → Kafka [order-created-topic] → Payment Service (处理支付)
  → Kafka [payment-result-topic] → Email Service (发送邮件)
  → Kafka [stock-update-topic] → Product Service (更新库存)
```

---

## 🛠 技术栈一览

| 分类 | 技术 | 版本 | 作用 |
|------|------|------|------|
| 核心框架 | Spring Boot | 3.3.3 | 微服务基础框架 |
| 服务发现 | Spring Cloud Netflix Eureka | 2023.0.3 | 服务注册与发现 |
| 网关 | Spring Cloud Gateway | 2023.0.3 | API路由、JWT过滤 |
| 消息队列 | Apache Kafka | 3.x | 异步事件驱动通信 |
| 安全 | Spring Security + JWT (jjwt 0.12.6) | - | 认证授权 |
| 数据库 | MySQL 8.x + Spring Data JPA | - | 数据持久化 |
| 缓存 | Redis (Lettuce + Jedis) | - | 分布式缓存 |
| 对象映射 | ModelMapper | 3.2.1 | DTO ↔ Entity 转换 |
| HTTP客户端 | Spring Cloud OpenFeign | - | 服务间HTTP调用 |
| 代码生成 | Lombok | 1.18.38 | 消除样板代码 |
| 容器化 | Docker + Docker Compose | - | 环境一致性 |
| 可观测性 | Micrometer + Brave + Zipkin | - | 分布式链路追踪 |
| API文档 | SpringDoc OpenAPI (Swagger) | 2.6.0 | 接口文档 |
| 邮件 | Spring Mail | - | 邮件通知 |
| 图片存储 | Cloudinary | 1.39.0 | 云端图片管理 |
| 支付 | PayPal SDK | 1.14.0 | 在线支付集成 |
| 公共库 | common-lib | 1.0.7 | 共享DTO/Entity |

---

## ⚡ 快速启动

### 前置条件

```bash
# 检查 Java 版本 (需要 17+)
java -version

# 检查 Maven
mvn -version

# 检查 Docker
docker --version
docker-compose --version
```

### Step 1: 构建公共库

```bash
cd common-lib
mvn clean install -DskipTests -Dgpg.skip=true
```

> **为什么先构建 common-lib？**
> `common-lib` 包含所有服务共用的 DTO (`OrderEvent`, `OrderItemDTO`, `ProductEvent` 等) 和 Entity 基类 (`AbstractEntity`)。
> 其他服务的 `pom.xml` 都声明了对它的依赖，必须先安装到本地 Maven 仓库。

### Step 2: 构建各微服务 JAR

```bash
# 按顺序构建（service-registry → api-gateway → 业务服务）
for service in service-registry api-gateway order-service payment-service email-service product-service identity-service; do
  echo "Building $service..."
  cd $service && mvn clean package -DskipTests -Dgpg.skip=true && cd ..
done
```

### Step 3: 一键启动所有服务

```bash
docker-compose up -d --build
```

### Step 4: 验证服务健康

```bash
# 查看所有容器状态
docker-compose ps

# 查看 Eureka 控制台（应该看到所有服务注册）
open http://localhost:8761

# 查看 API Gateway 路由
curl http://localhost:8080/actuator/gateway/routes

# 注册用户
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123","roles":["ROLE_USER"]}'

# 登录获取 JWT
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test@example.com","password":"password123"}'
```

---

## 📦 模块详解

### 服务端口映射

| 服务 | 端口 | 职责 |
|------|------|------|
| `service-registry` | 8761 | Eureka 服务注册中心 |
| `api-gateway` | 8080 | 统一入口、JWT验证、路由 |
| `product-service` | 8081 | 商品CRUD、库存管理、图片上传 |
| `order-service` | 8082 | 订单创建、状态机流转、PayPal支付 |
| `payment-service` | 8083 | 支付记录、退款处理 |
| `email-service` | 8084 | 消费Kafka事件、发送通知邮件 |
| `identity-service` | 8085 | 用户注册登录、JWT生成、角色管理 |

### common-lib 共享模型

```java
// OrderEvent — Kafka 消息载体
@Data
public class OrderEvent {
    private String message;
    private String status;
    private OrderDTO orderDTO;
    private String paymentMethod;
    private String email;
}

// AbstractEntity — 所有 Entity 的基类（审计字段）
@MappedSuperclass
public abstract class AbstractEntity {
    @CreatedDate
    private LocalDateTime createdAt;
    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

---

## 🎯 面试考点一：微服务架构设计

### Q1: 微服务与单体应用的区别？什么时候用微服务？

**单体应用（Monolith）：**
- 所有功能在一个进程中运行
- 优点：开发简单、部署简单、本地调试方便
- 缺点：随规模增大，部署风险高、技术栈固化、扩展困难

**微服务（Microservices）：**
- 每个业务域独立部署、独立扩展
- 优点：技术异构、独立扩展、故障隔离
- 缺点：网络复杂、分布式事务难、运维成本高

**判断标准：**
```
团队规模 > 10人 && 业务复杂度高 && 需要独立扩展不同模块 → 考虑微服务
```

### Q2: 本项目中服务间如何通信？同步 vs 异步怎么选择？

```
同步通信（OpenFeign）：
  order-service → product-service  查询商品信息（需要实时结果）
  order-service → payment-service  查询支付状态（需要实时结果）

异步通信（Kafka）：
  order-service → [kafka] → payment-service  触发支付（不需要等待）
  order-service → [kafka] → email-service    发送邮件（无需等待）
  order-service → [kafka] → product-service  更新库存（最终一致性）
```

**选择原则：**
- 需要立即返回结果 → 同步（OpenFeign/HTTP）
- 不需要立即结果、允许最终一致 → 异步（Kafka）
- 失败需要事务回滚 → 同步 or Saga 模式

### Q3: 服务发现的原理？Eureka vs Consul vs Nacos？

```
服务注册过程：
1. 服务启动 → 向 Eureka Server 发送 POST /eureka/apps/{appId} 注册
2. 每 30s 发送心跳（续约）
3. 超过 90s 未收到心跳 → 服务下线

客户端负载均衡：
消费方从 Eureka 拉取注册表 → 本地缓存 → 调用时从列表中选实例
```

**本项目配置：**
```yaml
# application.yml (各个服务)
eureka:
  client:
    service-url:
      defaultZone: http://eureka-server:8761/eureka/
  instance:
    prefer-ip-address: true
```

| 特性 | Eureka | Consul | Nacos |
|------|--------|--------|-------|
| 语言 | Java | Go | Java |
| 一致性模型 | AP（高可用）| CP（强一致）| AP+CP |
| 自我保护模式 | ✅ | ❌ | ✅ |
| 国内使用 | 较少 | 中等 | **广泛** |

### Q4: API Gateway 的核心作用？

```java
// api-gateway: 统一 JWT 过滤器
@Component
public class JwtAuthenticationFilter implements GlobalFilter {
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String token = extractToken(exchange.getRequest());
        if (token != null && jwtService.validateToken(token)) {
            // 将用户信息注入 Header，传递给下游服务
            exchange.getRequest().mutate()
                .header("X-User-Id", jwtService.extractUserId(token))
                .build();
            return chain.filter(exchange);
        }
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }
}
```

**Gateway 核心功能：**
1. **路由**：根据路径将请求转发到对应服务
2. **认证**：统一 JWT 验证，下游服务无需重复验证
3. **限流**：令牌桶/漏桶算法（Redis 实现）
4. **负载均衡**：集成 Ribbon/LoadBalancer
5. **熔断**：集成 Resilience4j

---

## 🎯 面试考点二：Spring Boot 核心

### Q5: Spring Boot 自动配置原理？

```java
// @SpringBootApplication 等价于：
@Configuration        // 标记为配置类
@EnableAutoConfiguration  // 关键！启用自动配置
@ComponentScan        // 扫描组件

// 自动配置核心流程：
// 1. 读取 META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
// 2. 根据 @ConditionalOnClass, @ConditionalOnMissingBean 判断是否生效
// 3. 自动创建 Bean 注入容器

// 示例：DataSource 自动配置
@ConditionalOnClass(DataSource.class)
@ConditionalOnMissingBean(DataSource.class)
@Configuration
public class DataSourceAutoConfiguration {
    @Bean
    public DataSource dataSource(DataSourceProperties properties) {
        return properties.initializeDataSourceBuilder().build();
    }
}
```

### Q6: Spring Bean 的生命周期？

```
实例化 → 属性注入 → BeanNameAware → BeanFactoryAware
→ ApplicationContextAware → @PostConstruct → InitializingBean.afterPropertiesSet()
→ init-method → [使用中] → @PreDestroy → DisposableBean.destroy() → destroy-method
```

### Q7: @Transactional 事务失效的场景？

```java
// ❌ 失效场景1：同一类内部调用（代理未生效）
@Service
public class OrderService {
    public void createOrder() {
        this.saveOrder(); // 直接调用，绕过代理！
    }

    @Transactional
    public void saveOrder() { ... }
}

// ❌ 失效场景2：非 public 方法
@Transactional
private void saveOrder() { ... } // private 无法被代理

// ❌ 失效场景3：异常被 catch 吞掉
@Transactional
public void createOrder() {
    try {
        orderRepo.save(order);
    } catch (Exception e) {
        log.error(e.getMessage()); // 吞掉异常，事务不回滚！
    }
}

// ✅ 正确做法：抛出 RuntimeException 或显式回滚
@Transactional(rollbackFor = Exception.class)
public void createOrder() throws Exception {
    orderRepo.save(order);
    // 如需手动回滚：
    // TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
}
```

### Q8: Spring 中 @Autowired 和构造器注入的区别？

```java
// ❌ 字段注入（本项目中 @Autowired 方式）
@Service
public class PaymentService {
    @Autowired
    private PaymentRepository paymentRepo; // 不推荐
}

// ✅ 构造器注入（本项目中 @RequiredArgsConstructor 方式）
@Service
@RequiredArgsConstructor // Lombok 生成构造器
public class PaymentService {
    private final PaymentRepository paymentRepo; // final 字段，不可变
}

// 构造器注入优势：
// 1. 依赖不可为 null（编译期保证）
// 2. 方便单元测试（不需要 Spring 容器）
// 3. 避免循环依赖（在启动时就报错，而非运行时）
```

---

## 🎯 面试考点三：Apache Kafka 消息队列

### Q9: Kafka 的核心概念？

```
Topic（主题）
├── Partition 0  [msg1, msg2, msg5, ...]  → Consumer A
├── Partition 1  [msg3, msg6, msg9, ...]  → Consumer B
└── Partition 2  [msg4, msg7, msg8, ...]  → Consumer C

Producer → Broker (Leader Partition) → Follower Replicas
Consumer Group: 同组内每个 Partition 只被一个 Consumer 消费
```

**本项目 Kafka 配置：**
```yaml
spring:
  kafka:
    bootstrap-servers: kafka:9092
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
    consumer:
      group-id: payment-group
      auto-offset-reset: earliest  # 从最早的消息开始消费
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
```

### Q10: 如何实现生产者端消息可靠性？

```java
// order-service: OrderProducer.java
@Service
@RequiredArgsConstructor
public class OrderProducer {
    private final KafkaTemplate<String, OrderEvent> kafkaTemplate;

    @Value("${spring.kafka.create-order-topic.name}")
    private String orderTopic;

    public void sendOrderEvent(OrderEvent orderEvent) {
        // 使用 CompletableFuture 处理异步回调
        CompletableFuture<SendResult<String, OrderEvent>> future =
            kafkaTemplate.send(orderTopic, orderEvent);

        future.whenComplete((result, ex) -> {
            if (ex != null) {
                // 发送失败：重试或写入死信队列
                log.error("Failed to send OrderEvent: {}", ex.getMessage());
            } else {
                log.info("OrderEvent sent: topic={}, partition={}, offset={}",
                    result.getRecordMetadata().topic(),
                    result.getRecordMetadata().partition(),
                    result.getRecordMetadata().offset());
            }
        });
    }
}

// Producer 可靠性配置：
spring.kafka.producer.acks=all        # 所有副本确认
spring.kafka.producer.retries=3       # 失败重试次数
spring.kafka.producer.enable.idempotence=true  # 幂等性（防止重复）
```

### Q11: 消费者如何保证消息不丢失、不重复消费？

```java
// payment-service: OrderConsumer.java
@Component
@RequiredArgsConstructor
public class OrderConsumer {

    @KafkaListener(
        topics = "${spring.kafka.create-order-topic.name}",
        groupId = "${spring.kafka.consumer.group-id}"
    )
    @Transactional  // 与数据库事务绑定
    public void consume(OrderEvent orderEvent) {
        log.info("Received OrderEvent: {}", orderEvent);

        // 幂等性处理：检查是否已处理过该消息
        if (paymentRepo.existsByOrderId(orderEvent.getOrderDTO().getOrderId())) {
            log.warn("Duplicate message, orderId already processed");
            return;
        }

        // 处理业务逻辑
        paymentService.createPayment(orderEvent);
        // 业务成功后，offset 才会提交（enable.auto.commit=false）
    }
}
```

**至少一次 vs 最多一次 vs 精确一次：**

| 语义 | 配置 | 实现方式 |
|------|------|----------|
| 最多一次 | `acks=0` | 发送后不管结果 |
| 至少一次 | `acks=all + 重试` | 可能重复，需业务幂等 |
| 精确一次 | 事务性生产者 + 幂等消费者 | 最复杂，性能最低 |

### Q12: Kafka 与 RabbitMQ 的区别？

| 维度 | Kafka | RabbitMQ |
|------|-------|----------|
| 消息模型 | 发布-订阅（持久化日志）| AMQP（队列）|
| 吞吐量 | 极高（百万/秒）| 较低（万/秒）|
| 消息保留 | 配置时间/大小保留 | 消费后删除 |
| 顺序性 | Partition 内有序 | 队列内有序 |
| 适用场景 | 日志、流处理、事件溯源 | 任务队列、RPC |

---

## 🎯 面试考点四：Spring Security + JWT

### Q13: JWT 的结构和工作原理？

```
JWT = Header.Payload.Signature

Header: {"alg": "HS256", "typ": "JWT"}
Payload: {
  "sub": "user123",
  "email": "user@example.com",
  "roles": ["ROLE_USER"],
  "iat": 1709640000,
  "exp": 1709726400
}
Signature = HMACSHA256(base64(header) + "." + base64(payload), secret)
```

**本项目 JWT 实现：**
```java
// identity-service: JwtServiceImpl.java
@Service
public class JwtServiceImpl implements JwtService {

    @Value("${application.security.jwt.secret-key}")
    private String secretKey;

    @Value("${application.security.jwt.expiration}")
    private long jwtExpiration; // 86400000ms = 24h

    public String generateToken(UserDetails userDetails) {
        CustomUserDetails user = (CustomUserDetails) userDetails;
        return Jwts.builder()
            .subject(user.getUsername())
            .claim("email", user.getEmail())
            .claim("permissions", user.getPermissions())
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
            .signWith(getSigningKey())
            .compact();
    }

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secretKey));
    }
}
```

### Q14: Spring Security 的过滤器链？

```
请求 → SecurityFilterChain
  → CorsFilter
  → SecurityContextPersistenceFilter
  → UsernamePasswordAuthenticationFilter (登录)
  → JwtAuthenticationFilter (自定义JWT验证) ← 本项目
  → ExceptionTranslationFilter
  → FilterSecurityInterceptor (权限判断)
  → Controller
```

```java
// identity-service: SecurityConfiguration.java
@Configuration
@EnableWebSecurity
public class SecurityConfiguration {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // 无状态
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()  // 公开端点
                .anyRequest().authenticated()                     // 其余需认证
            )
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }
}
```

---

## 🎯 面试考点五：数据库与JPA

### Q15: JPA / Hibernate 的 N+1 问题？

```java
// ❌ N+1 问题示例
List<Order> orders = orderRepo.findAll();  // 1次查询
for (Order order : orders) {
    // 每个 Order 都触发一次 SELECT 查询 OrderItems！= N次
    List<OrderItem> items = order.getOrderItems();
}

// ✅ 解决方案1：JOIN FETCH
@Query("SELECT o FROM Order o JOIN FETCH o.orderItems WHERE o.userId = :userId")
List<Order> findAllWithItems(@Param("userId") String userId);

// ✅ 解决方案2：EntityGraph
@EntityGraph(attributePaths = {"orderItems"})
List<Order> findByUserId(String userId);

// ✅ 解决方案3：批量加载
@BatchSize(size = 20)
@OneToMany(mappedBy = "order")
private List<OrderItem> orderItems;
```

### Q16: 常见 JPA 关系映射？

```java
// order-service: Order Entity
@Entity
@Table(name = "orders")
@Getter @Setter @NoArgsConstructor
public class Order extends AbstractEntity {

    @Id
    private String id;

    // 一对多：一个订单多个商品
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> orderItems = new ArrayList<>();

    // 枚举类型转换
    @Convert(converter = OrderStatusConverter.class)
    private OrderStatus status;
}

// 双向关联的坑：需要维护两端一致性
public void addOrderItem(OrderItem item) {
    orderItems.add(item);
    item.setOrder(this); // 必须设置！
}
```

### Q17: 数据库索引策略？

```sql
-- product_service 商品表可能的索引
CREATE INDEX idx_product_category ON products(category_id);  -- 按分类查询
CREATE INDEX idx_product_name ON products(name);             -- 按名称搜索
CREATE INDEX idx_product_price ON products(price);           -- 按价格排序

-- 复合索引遵循最左前缀原则
CREATE INDEX idx_order_user_status ON orders(user_id, status, created_at);
-- ✅ WHERE user_id = ? → 走索引
-- ✅ WHERE user_id = ? AND status = ? → 走索引
-- ❌ WHERE status = ? → 不走索引（缺少最左列 user_id）
```

---

## 🎯 面试考点六：Redis 缓存

### Q18: 本项目如何使用 Redis？

```java
// payment-service: PaymentRedis.java
@Component
@RequiredArgsConstructor
public class PaymentRedis {

    private final RedisTemplate<String, Object> redisTemplate;

    private static final String PAYMENT_PREFIX = "payment:";
    private static final long TTL_HOURS = 24;

    // 缓存支付信息
    public void savePayment(Payment payment) {
        String key = PAYMENT_PREFIX + payment.getOrderId();
        redisTemplate.opsForValue().set(key, payment, TTL_HOURS, TimeUnit.HOURS);
    }

    // 查询（缓存穿透防护）
    public Payment getPaymentByOrderId(String orderId) {
        String key = PAYMENT_PREFIX + orderId;
        Payment cached = (Payment) redisTemplate.opsForValue().get(key);
        if (cached != null) {
            return cached; // 缓存命中
        }
        // 缓存未命中，查数据库
        Payment payment = paymentRepo.findByOrderId(orderId)
            .orElseThrow(() -> new RuntimeException("Payment not found"));
        savePayment(payment); // 回填缓存
        return payment;
    }
}
```

### Q19: Redis 缓存三大问题？

```
缓存穿透：查询不存在的 key → 每次都打到数据库
  解决：布隆过滤器 / 缓存空值（TTL 短）

缓存击穿：热点 key 过期瞬间大量请求 → 同时打到数据库
  解决：互斥锁（SETNX）/ 逻辑过期（不设TTL，异步更新）

缓存雪崩：大量 key 同时过期 / Redis 宕机
  解决：随机TTL / Redis 集群 / 本地缓存兜底
```

```java
// 互斥锁解决缓存击穿（防止大量请求同时查DB）
public Payment getWithMutex(String orderId) {
    Payment payment = getFromCache(orderId);
    if (payment != null) return payment;

    // 尝试获取分布式锁
    String lockKey = "lock:payment:" + orderId;
    Boolean locked = redisTemplate.opsForValue()
        .setIfAbsent(lockKey, "1", 10, TimeUnit.SECONDS);

    if (Boolean.TRUE.equals(locked)) {
        try {
            payment = paymentRepo.findByOrderId(orderId).orElseThrow();
            saveToCache(orderId, payment);
        } finally {
            redisTemplate.delete(lockKey); // 释放锁
        }
    } else {
        Thread.sleep(50); // 等待后重试
        return getWithMutex(orderId);
    }
    return payment;
}
```

---

## 🎯 面试考点七：API Gateway & 服务发现

### Q20: Spring Cloud Gateway vs Zuul 的区别？

| 特性 | Spring Cloud Gateway | Zuul 1.x |
|------|---------------------|----------|
| 编程模型 | 响应式 (WebFlux/Netty) | 阻塞 (Servlet) |
| 性能 | 高（非阻塞IO）| 较低（线程模型）|
| 过滤器 | GlobalFilter + GatewayFilter | ZuulFilter |
| 版本支持 | Spring Boot 3.x ✅ | 已停止维护 ❌ |

**本项目网关路由配置：**
```yaml
# api-gateway/application.yml
spring:
  cloud:
    gateway:
      routes:
        - id: order-service
          uri: lb://order-service          # lb:// 启用负载均衡
          predicates:
            - Path=/api/v1/orders/**
          filters:
            - StripPrefix=0
            - name: RequestRateLimiter     # 限流过滤器
              args:
                redis-rate-limiter.replenishRate: 10
                redis-rate-limiter.burstCapacity: 20

        - id: identity-service
          uri: lb://identity-service
          predicates:
            - Path=/api/v1/auth/**
          filters:
            - StripPrefix=0
```

---

## 🎯 面试考点八：分布式事务与一致性

### Q21: 本项目订单支付的最终一致性如何保证？

```
传统方案（强一致性/2PC）：
  OrderService 和 PaymentService 在同一事务中 → 性能差，不适合微服务

本项目方案（Saga 最终一致性）：
  1. OrderService 创建订单（状态: PENDING）
  2. 发布 Kafka 事件 [order.created]
  3. PaymentService 消费事件 → 处理支付
  4a. 支付成功 → 发布 [payment.success] → OrderService 更新状态 PAID
  4b. 支付失败 → 发布 [payment.failed] → OrderService 更新状态 FAILED（补偿事务）
```

**Saga 模式的两种实现：**

```
编排式 Saga（本项目采用）：
  各服务通过 Kafka 事件协作，没有中央协调者
  优点：松耦合，灵活
  缺点：业务逻辑分散，难以追踪整个流程

指挥式 Saga：
  由中央 Orchestrator 服务告诉每个参与者执行什么
  优点：流程集中，易于监控
  缺点：Orchestrator 成为单点和瓶颈
```

### Q22: 如何保证 Kafka 消费的幂等性？

```java
// 方法1：数据库唯一约束
@UniqueConstraint(name = "uk_order_id", columnNames = "order_id")
public class Payment { ... }

// 方法2：Redis 去重
public void consume(OrderEvent event) {
    String dedupeKey = "processed:order:" + event.getOrderDTO().getOrderId();
    Boolean isNew = redisTemplate.opsForValue()
        .setIfAbsent(dedupeKey, "1", 24, TimeUnit.HOURS);

    if (Boolean.FALSE.equals(isNew)) {
        log.warn("Duplicate event, skipping: {}", event);
        return;
    }
    // 处理业务逻辑
}
```

---

## 🎯 面试考点九：Docker 容器化

### Q23: Dockerfile 最佳实践？

```dockerfile
# 本项目服务 Dockerfile
FROM eclipse-temurin:17-jre        # ✅ 使用 JRE（不是JDK），减小镜像体积

WORKDIR /app

COPY target/payment-service.jar /app/payment-service.jar  # ✅ 只复制必要文件

EXPOSE 8083

# ✅ 使用数组形式（exec模式），支持 SIGTERM 优雅关闭
ENTRYPOINT ["java", "-jar", "payment-service.jar"]

# 生产优化（可添加）：
# ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75", "-jar", "payment-service.jar"]
```

**镜像分层优化（多阶段构建）：**
```dockerfile
# 多阶段构建（更优方案）
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline  # 缓存依赖层
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
COPY --from=build /app/target/payment-service.jar .
ENTRYPOINT ["java", "-jar", "payment-service.jar"]
```

### Q24: docker-compose 关键配置解读？

```yaml
# docker-compose.yml 关键片段解析
services:
  kafka:
    image: confluentinc/cp-kafka:latest
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092  # 容器内部访问地址
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1          # 单节点测试用1
    depends_on:
      - zookeeper  # 依赖顺序（但不等health check!）

  order-service:
    build:
      context: ./order-service              # Dockerfile 所在目录
    environment:
      SPRING_PROFILES_ACTIVE: docker       # 激活 docker profile
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092  # 覆盖配置
    depends_on:
      - kafka
      - mysql-order-service
      - eureka-server
    networks:
      - shop-network  # 自定义网络，容器间可用服务名互通

networks:
  shop-network:
    driver: bridge    # 默认网络模式
```

---

## 🎯 面试考点十：可观测性与调用链追踪

### Q25: 分布式链路追踪原理？

```
请求从 API Gateway → Order Service → Payment Service 的全链路追踪：

Trace ID: abc123  (整条链路唯一ID)
  ├── Span 1: api-gateway (50ms)
  ├── Span 2: order-service (120ms)
  │   ├── DB查询: 30ms
  │   └── Kafka发送: 5ms
  └── Span 3: payment-service (80ms)

自动注入 Header:
  X-B3-TraceId: abc123
  X-B3-SpanId: def456
  X-B3-ParentSpanId: ghi789
```

**本项目配置（Micrometer + Brave + Zipkin）：**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-brave</artifactId>
</dependency>
<dependency>
    <groupId>io.zipkin.reporter2</groupId>
    <artifactId>zipkin-reporter-brave</artifactId>
</dependency>
```

```yaml
# application.yml
management:
  tracing:
    sampling:
      probability: 1.0  # 100% 采样（生产环境用 0.1）
  zipkin:
    tracing:
      endpoint: http://zipkin:9411/api/v2/spans
```

---

## 🎯 面试考点十一：设计模式实战

### Q26: 本项目中使用了哪些设计模式？

**1. 状态机模式（Order Status Flow）**
```java
// order-service: 订单状态流转
public interface OrderState {
    void next(OrderContext context);
}

public class NewOrderState implements OrderState {
    @Override
    public void next(OrderContext context) {
        context.getOrder().setStatus(OrderStatus.PROCESSING.getLabel());
    }
}

public class OrderContext {
    private Order order;
    private OrderState state;

    public void nextState() {
        state.next(this); // 委托给当前状态处理
        // 状态根据当前值决定下一个
        switch (order.getStatus()) {
            case "PROCESSING" -> state = new ProcessingOrderState();
            case "SHIPPING"   -> state = new ShippingOrderState();
            case "DELIVERED"  -> state = new ShippingOrderState();
        }
    }
}
```

**2. 建造者模式（Lombok @Builder）**
```java
OrderEvent event = OrderEvent.builder()
    .message("Order created")
    .status("PENDING")
    .orderDTO(orderDTO)
    .paymentMethod("PAYPAL")
    .email(user.getEmail())
    .build();
```

**3. 模板方法模式（AbstractEntity）**
```java
@MappedSuperclass
public abstract class AbstractEntity {
    @CreatedDate
    private LocalDateTime createdAt;    // 自动填充

    @LastModifiedDate
    private LocalDateTime updatedAt;    // 自动填充
    // 所有 Entity 自动获得审计功能，无需重复代码
}
```

**4. 门面模式（Service 层）**
```java
// OrderService 作为门面，协调多个Repository和其他Service
@Service
public class OrderServiceImpl implements OrderService {
    private final OrderRepository orderRepo;        // 数据访问
    private final ProductAPIClient productClient;   // 远程服务
    private final PaymentAPIClient paymentClient;   // 远程服务
    private final OrderProducer kafkaProducer;      // 消息发布
    private final OrderRedis redisCache;            // 缓存

    // 对外提供简单接口，内部协调多个组件
    public OrderResponseDto createOrder(OrderRequestDto request) { ... }
}
```

---

## 🎯 面试考点十二：并发与性能

### Q27: Java 中 synchronized vs ReentrantLock？

```java
// synchronized：简单场景，JVM 内置
public synchronized void processPayment(String orderId) { ... }

// ReentrantLock：需要更细粒度控制
private final ReentrantLock lock = new ReentrantLock();

public void processPayment(String orderId) {
    if (lock.tryLock(5, TimeUnit.SECONDS)) {  // 超时获取锁
        try {
            // 临界区
        } finally {
            lock.unlock(); // 必须在 finally 释放！
        }
    }
}

// 分布式场景用 Redis 分布式锁（见缓存击穿解决方案）
```

### Q28: Spring Boot 如何优化应用性能？

```yaml
# application.yml 性能优化配置
server:
  tomcat:
    max-threads: 200          # 最大线程数（默认200）
    min-spare-threads: 10     # 最小空闲线程
    connection-timeout: 5000  # 连接超时5s

spring:
  datasource:
    hikari:
      maximum-pool-size: 20   # 连接池最大连接数
      minimum-idle: 5         # 最小空闲连接
      connection-timeout: 30000       # 获取连接超时
      idle-timeout: 600000            # 空闲连接超时10min

  jpa:
    properties:
      hibernate:
        jdbc:
          batch_size: 50      # 批量写入大小
        order_inserts: true   # 批量insert排序
```

```java
// 异步处理：@Async
@Service
public class EmailService {

    @Async("emailTaskExecutor")  // 指定线程池
    public void sendEmail(String to, String content) {
        // 在单独线程池中执行，不阻塞主线程
        mailSender.send(...);
    }
}

@Configuration
public class AsyncConfig {
    @Bean("emailTaskExecutor")
    public Executor emailTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(20);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("email-");
        return executor;
    }
}
```

---

## 📍 项目实践路线图

按以下顺序学习，循序渐进：

```
Week 1: 基础
  □ 克隆项目，成功运行 docker-compose up
  □ 通过 Swagger UI 测试所有 API 端点
  □ 阅读 common-lib 源码，理解共享 DTO 设计

Week 2: 深入服务
  □ 调试 identity-service：注册→登录→JWT验证完整流程
  □ 调试 order-service：创建订单 → Kafka 事件发布
  □ 在 Kafka 日志中追踪消息流转

Week 3: 扩展练习
  □ 为 product-service 添加商品搜索功能（全文检索）
  □ 为任意服务添加 Redis 缓存层
  □ 为关键接口添加 Swagger 注解

Week 4: 生产化
  □ 添加 Resilience4j 熔断器
  □ 配置 Zipkin 查看分布式链路
  □ 编写单元测试和集成测试
  □ 配置 CI/CD（GitHub Actions）
```

---

## 🤝 贡献指南

欢迎提 Issue 和 PR！如果这个项目对你有帮助，请点个 ⭐ Star 支持一下！

## 📄 License

MIT License
