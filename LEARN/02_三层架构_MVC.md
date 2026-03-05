# 第二章：三层架构 —— 代码为什么要分成 Controller / Service / Repository？

---

## 📚 全部章节导航

- [00_从零开始学Spring Boot](./00_从零开始学Spring Boot.md)
- [01_Spring_Boot是什么](./01_Spring_Boot是什么.md)
- [02_三层架构_MVC](./02_三层架构_MVC.md)
- [03_依赖注入_IOC](./03_依赖注入_IOC.md)
- [04_数据库_JPA_MySQL](./04_数据库_JPA_MySQL.md)
- [05_REST_API设计](./05_REST_API设计.md)
- [06_微服务是什么](./06_微服务是什么.md)
- [07_Kafka消息队列](./07_Kafka消息队列.md)
- [08_JWT身份认证](./08_JWT身份认证.md)
- [09_Docker容器化](./09_Docker容器化.md)
- [10_面试模拟_项目讲解话术](./10_面试模拟_项目讲解话术.md)

---



> 读完这章，你能回答：
> - "为什么要把代码分成三层？"
> - "Controller、Service、Repository 各自负责什么？"
> - "一个 HTTP 请求是怎么流经这三层的？"

---

## 📖 Part 1：从你懂的 Java 出发

### 假设你要写一个功能：用户查询自己的支付记录

**不分层的写法（你可能会这样写）：**

```java
// 把所有东西堆在一个地方
public class PaymentStuff {

    public void getPayment(String orderId) {
        // HTTP 请求处理 + 业务逻辑 + 数据库操作 全在一起
        System.out.println("收到请求，订单ID：" + orderId);

        // 直接写 SQL
        Connection conn = DriverManager.getConnection("jdbc:mysql://...");
        PreparedStatement stmt = conn.prepareStatement(
            "SELECT * FROM payments WHERE order_id = ?");
        stmt.setString(1, orderId);
        ResultSet rs = stmt.executeQuery();

        // 判断业务逻辑
        if (rs.next()) {
            BigDecimal amount = rs.getBigDecimal("amount");
            if (amount.compareTo(BigDecimal.ZERO) > 0) {
                System.out.println("支付成功，金额：" + amount);
            }
        }
    }
}
```

**这样写的问题：**
- 🔴 改个 SQL → 要找这个大文件 → 可能改坏其他部分
- 🔴 想复用"查支付"这个功能 → 不可能，全耦合在一起
- 🔴 测试困难 → 一个方法测试时要连数据库
- 🔴 代码越来越长，越来越难懂

---

### 三层架构的思想：**职责分离**

就像餐厅的分工：

```
服务员（Controller）：负责接待顾客，接收点单，把菜端给顾客
    ↓ 把点单传给
厨师（Service）：负责做菜，处理业务逻辑（用什么食材、怎么做）
    ↓ 需要食材时找
仓库管理员（Repository）：负责存取食材，操作数据库
```

**规则：**
- 服务员不能自己去仓库取东西（Controller 不直接操作数据库）
- 厨师不接待顾客（Service 不处理 HTTP 请求）
- 每层只做自己的事

---

## 💻 Part 2：在这个项目里怎么用？

### 追踪一个真实请求的旅程

**场景：** 用户调用 GET `/api/v1/payments/order123`，查询订单123的支付信息。

---

#### 第一站：Controller（接待员）

```
路径：payment-service/src/main/java/.../controller/PaymentController.java
```

```java
@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor  // Lombok：自动生成包含所有 final 字段的构造方法
public class PaymentController {

    // 注意：这里只是声明"我需要一个 PaymentService"
    // 不是 new PaymentService()！
    // Spring 会自动把 PaymentService 的实现塞进来（这叫依赖注入，下章讲）
    private final PaymentService paymentService;

    @GetMapping("/{orderId}")
    public ResponseEntity<?> getPaymentByOrderId(@PathVariable String orderId) {
        // Controller 做的事：
        // 1. 接收 orderId（从 URL 里提取）
        // 2. 调用 Service 处理
        // 3. 把结果包装成 HTTP 响应返回
        return ResponseEntity.ok(paymentService.getPaymentByOrderId(orderId));
        //                    ↑                 ↑
        //                  HTTP 200 状态码    调用 Service，让它去处理业务
    }
}
```

**Controller 的规则：**
- ❌ 不写业务逻辑（不判断支付状态、不计算金额）
- ❌ 不直接操作数据库
- ✅ 只负责：收请求 → 调 Service → 返结果

---

#### 第二站：Service（厨师）

```
路径：payment-service/src/main/java/.../service/impl/PaymentServiceImpl.java
```

```java
@Service  // 告诉 Spring：这是一个服务类，帮我管理它
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {

    private final PaymentRepository paymentRepo;
    private final PaymentRedis paymentRedis;  // Redis 缓存

    @Override
    public Payment getPaymentByOrderId(String orderId) {
        // Service 做的事：处理业务逻辑
        
        // 业务逻辑1：先查 Redis 缓存，有就直接返回（快！）
        Payment cached = paymentRedis.getPaymentByOrderId(orderId);
        if (cached != null) {
            return cached;
        }
        
        // 业务逻辑2：缓存没有，去数据库查
        Payment payment = paymentRepo.findByOrderId(orderId)
            .orElseThrow(() -> new RuntimeException("Payment not found: " + orderId));
        
        // 业务逻辑3：查到了，存入缓存，下次查快一点
        paymentRedis.savePayment(payment);
        
        return payment;
    }
}
```

**Service 的规则：**
- ✅ 写业务逻辑（该不该退款？金额对不对？先查缓存还是数据库？）
- ✅ 调用 Repository 操作数据库
- ❌ 不处理 HTTP 请求和响应
- ❌ 不知道谁在调用它（可以是 Controller，也可以是 Kafka 消费者）

---

#### 第三站：Repository（仓库管理员）

```
路径：payment-service/src/main/java/.../repository/PaymentRepository.java
```

```java
@Repository  // 告诉 Spring：这是数据库操作接口
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    // 这个接口几乎是空的！
    // JpaRepository 已经给你提供了所有基本操作：
    // - save(payment)          保存
    // - findById(id)           按 ID 查找
    // - findAll()              查所有
    // - delete(payment)        删除

    // 你只需要加上业务特殊的查询：
    Optional<Payment> findByOrderId(String orderId);
    //                              ↑
    // Spring Data JPA 看到这个方法名，自动生成 SQL：
    // SELECT * FROM payments WHERE order_id = ?
    // 你不需要写 SQL！（方法名就是查询条件）
    
    boolean existsByOrderId(String orderId);
    // 同理，自动生成：SELECT COUNT(*) > 0 FROM payments WHERE order_id = ?
}
```

**Repository 的规则：**
- ✅ 只负责操作数据库（查、增、改、删）
- ❌ 不写业务逻辑
- ❌ 不处理 HTTP 请求

---

### 完整请求流程图

```
浏览器 GET /api/v1/payments/order123
    ↓
PaymentController.getPaymentByOrderId("order123")
    ↓ 调用
PaymentServiceImpl.getPaymentByOrderId("order123")
    ↓ 先查 Redis 缓存
    ↓ 缓存没有，调用
PaymentRepository.findByOrderId("order123")
    ↓ 执行 SQL
MySQL 数据库返回 Payment 记录
    ↓ 返回给 Service
Service 存入 Redis 缓存，返回给 Controller
    ↓ 返回给
Controller 包装成 JSON，通过 HTTP 返回给浏览器
```

---

## 🔑 理解注解（Annotation）是什么

你在 Java OOP 里学过**接口**（interface）吧？注解是类似的概念，只是它是加在类或方法上的"标签"。

```java
// 你熟悉的：
public class Dog implements Animal { ... }

// 注解是加在类/方法上的特殊标记：
@Service  ← 这个"标签"告诉 Spring："这个类是 Service，你来管理它"
public class PaymentServiceImpl implements PaymentService { ... }
```

**重要注解速查表：**

| 注解 | 加在哪 | 含义 |
|------|--------|------|
| `@RestController` | 类 | 处理 HTTP 请求的控制器 |
| `@Service` | 类 | 业务逻辑层的 Service |
| `@Repository` | 类/接口 | 数据库操作层 |
| `@Component` | 类 | 通用组件（上面三个都是它的特殊版） |
| `@GetMapping("/path")` | 方法 | 处理 GET 请求 |
| `@PostMapping("/path")` | 方法 | 处理 POST 请求 |
| `@PathVariable` | 参数 | 从 URL 路径取值，如 `/users/{id}` |
| `@RequestBody` | 参数 | 从请求体取 JSON 数据 |

---

### 认识 Entity：数据库表 ↔ Java 类的对应关系

```
路径：payment-service/src/main/java/.../entity/Payment.java
```

```java
@Entity                          // 这个类对应数据库里的一张表
@Table(name = "payments")        // 表名叫 "payments"
@Getter @Setter                  // Lombok：自动生成所有 getter/setter
@NoArgsConstructor               // Lombok：自动生成无参构造方法
@AllArgsConstructor              // Lombok：自动生成全参构造方法
public class Payment extends AbstractEntity {

    @Id                          // 这个字段是主键
    private String id;

    @Column(nullable = false)    // 对应数据库列，不能为空
    private String orderId;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String paymentMethod; // "PAYPAL", "CREDIT_CARD" 等

    @Convert(converter = PaymentStatusConverter.class)
    private PaymentStatus status; // 枚举：PENDING, SUCCESS, FAILED, REFUND
}
```

**对应的数据库表长这样：**

```sql
CREATE TABLE payments (
    id          VARCHAR(255) PRIMARY KEY,
    order_id    VARCHAR(255) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    status      VARCHAR(20)
);
```

**Entity 类 ↔ 数据库表，一一对应！**

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: 解释一下 MVC 或者三层架构？**

> 🗣️ 你的答法：
>
> "三层架构是将代码按职责分成三层：
> Controller 层负责接收 HTTP 请求并返回响应，不包含业务逻辑；
> Service 层负责业务逻辑，比如验证数据、调用多个接口、处理缓存；
> Repository 层负责和数据库交互。
> 这种分层让代码职责清晰，易于维护和测试。
> 在我的项目里，每个微服务都遵循这个结构，比如 payment-service 的
> PaymentController → PaymentServiceImpl → PaymentRepository 这个链条。"

---

**Q: @Service 和 @Component 有什么区别？**

> 🗣️ 你的答法：
>
> "@Service 是 @Component 的特殊版本，本质上功能一样，
> 都是让 Spring 管理这个类。
> 区别是语义：@Service 表示这是业务逻辑层，
> @Repository 表示是数据访问层，
> @Controller 表示是请求处理层。
> 用这些语义化注解能让代码更清晰地表达意图。"

---

**Q: DTO 是什么？为什么不直接用 Entity？**

> 🗣️ 你的答法：
>
> "DTO（Data Transfer Object）是专门用来传输数据的类。
> Entity 是和数据库表对应的类，可能包含敏感字段（比如密码）
> 或者数据库内部字段（比如创建时间）。
> 我们不想把这些原封不动地暴露给用户。
> DTO 让我们可以控制哪些字段给前端，哪些不给。
> 在项目中用 ModelMapper 来自动把 Entity 转换成 DTO。"

---

## ✅ 第二章检查清单

- [ ] 能说清楚 Controller / Service / Repository 各负责什么
- [ ] 知道一个 HTTP 请求是怎么流经三层的
- [ ] 理解 `@RestController`, `@Service`, `@Repository` 是什么
- [ ] 知道 Entity 和数据库表的关系
- [ ] 知道 DTO 是什么

✅ 全部搞定 → 去看第三章（依赖注入）！



---

## 📚 全部章节导航

- [00_从零开始学Spring Boot](./00_从零开始学Spring Boot.md)
- [01_Spring_Boot是什么](./01_Spring_Boot是什么.md)
- [02_三层架构_MVC](./02_三层架构_MVC.md)
- [03_依赖注入_IOC](./03_依赖注入_IOC.md)
- [04_数据库_JPA_MySQL](./04_数据库_JPA_MySQL.md)
- [05_REST_API设计](./05_REST_API设计.md)
- [06_微服务是什么](./06_微服务是什么.md)
- [07_Kafka消息队列](./07_Kafka消息队列.md)
- [08_JWT身份认证](./08_JWT身份认证.md)
- [09_Docker容器化](./09_Docker容器化.md)
- [10_面试模拟_项目讲解话术](./10_面试模拟_项目讲解话术.md)

---
