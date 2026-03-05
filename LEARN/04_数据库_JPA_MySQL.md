# 第四章：数据库与 JPA —— 不写 SQL 也能操作数据库

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
> - "JPA 是什么？Hibernate 是什么？它们什么关系？"
> - "为什么不用 JDBC 写 SQL？"
> - "findByOrderId 这个方法名是怎么变成 SQL 的？"
> - "MySQL 和 JPA 在你的项目中怎么配置的？"

---

## 📖 Part 1：从你懂的 Java 出发

### 用原生 JDBC 操作数据库有多痛苦？

```java
// 你可能学过 JDBC，大概长这样：
public Payment findByOrderId(String orderId) {
    String sql = "SELECT * FROM payments WHERE order_id = ?";
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/payment_db", "root", "password");
        stmt = conn.prepareStatement(sql);
        stmt.setString(1, orderId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            Payment payment = new Payment();
            payment.setId(rs.getString("id"));
            payment.setOrderId(rs.getString("order_id"));
            payment.setAmount(rs.getBigDecimal("amount"));
            payment.setPaymentMethod(rs.getString("payment_method"));
            // ... 每个字段都要手动取出来！
            return payment;
        }
    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        // 三个 if 检查 null，三个 close()
        // 忘记 close 就泄露数据库连接！
        if (rs != null) rs.close();
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
    }
    return null;
}
```

**痛点：**
- 🔴 重复代码（连接、关闭、异常处理）
- 🔴 手动映射每个字段（`rs.getString("order_id")`）
- 🔴 SQL 是字符串，编译器不检查拼写错误
- 🔴 换数据库（MySQL → PostgreSQL）要改所有 SQL

---

### JPA 让你这样做：

```java
// 整个数据库操作！就这两行！

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Optional<Payment> findByOrderId(String orderId);
}

// 不需要写 SQL！不需要手动映射！不需要关连接！
// Spring Data JPA 根据方法名自动生成 SQL 并执行！
```

---

## 💻 Part 2：在这个项目里怎么用？

### 三个关键概念

```
JPA（Java Persistence API）        = 规范/标准（说了"应该怎么做"）
Hibernate                          = JPA 的实现（真正干活的人）
Spring Data JPA                    = 更上层的简化工具（让你写更少代码）

类比：
  JPA               = 交通规则（规定了红灯停绿灯行）
  Hibernate          = 汽车引擎（真正在跑的东西）
  Spring Data JPA    = 自动驾驶（你只管说去哪，它帮你开）
```

---

### 1. Entity：Java 类 ↔ 数据库表

```java
// 路径：payment-service/.../entity/Payment.java

@Entity                          // "这个类对应数据库的一张表"
@Table(name = "payments")        // 表名是 payments
@Getter @Setter                  // Lombok 生成 getter/setter
@NoArgsConstructor @AllArgsConstructor
public class Payment extends AbstractEntity {

    @Id                          // 这是主键
    private String id;

    @Column(nullable = false)    // 数据库列，NOT NULL
    private String orderId;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String paymentMethod;

    @Convert(converter = PaymentStatusConverter.class)
    private PaymentStatus status;
}

// Java 类              ↔  数据库表
// ------------------------------------------
// @Entity Payment      ↔  CREATE TABLE payments
// private String id     ↔  id VARCHAR(255) PRIMARY KEY
// private String orderId↔  order_id VARCHAR(255) NOT NULL
// private BigDecimal amount ↔ amount DECIMAL NOT NULL
```

**重要！** JPA 会根据你的 Entity 类**自动创建数据库表**！
（配置 `spring.jpa.hibernate.ddl-auto=update` 时）

---

### 2. Repository：方法名 → SQL（魔法！）

```java
// 路径：payment-service/.../repository/PaymentRepository.java

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    //                                        ↑           ↑
    //                                   操作哪个 Entity   主键类型
    
    // JpaRepository 白送你的方法（不用写！）：
    // save(Payment entity)       → INSERT INTO payments ...
    // findById(Long id)          → SELECT * FROM payments WHERE id = ?
    // findAll()                  → SELECT * FROM payments
    // deleteById(Long id)        → DELETE FROM payments WHERE id = ?
    // count()                    → SELECT COUNT(*) FROM payments
    
    // 你只需要写"方法名"，Spring 自动生成 SQL：
    
    Optional<Payment> findByOrderId(String orderId);
    // 自动生成 → SELECT * FROM payments WHERE order_id = ?
    
    boolean existsByOrderId(String orderId);
    // 自动生成 → SELECT COUNT(*) > 0 FROM payments WHERE order_id = ?
    
    List<Payment> findByStatus(PaymentStatus status);
    // 自动生成 → SELECT * FROM payments WHERE status = ?
    
    List<Payment> findByAmountGreaterThanAndStatus(BigDecimal amount, PaymentStatus status);
    // 自动生成 → SELECT * FROM payments WHERE amount > ? AND status = ?
}
```

**方法名规则：**

```
findBy + 字段名 + 条件关键字

关键字：
  And              → AND
  Or               → OR
  GreaterThan      → >
  LessThan         → <
  Like             → LIKE
  OrderBy          → ORDER BY
  Between          → BETWEEN
  IsNull           → IS NULL
  
例子：
  findByNameAndAge(String name, int age)
  → SELECT * FROM users WHERE name = ? AND age = ?
  
  findByPriceLessThanOrderByNameAsc(BigDecimal price)
  → SELECT * FROM users WHERE price < ? ORDER BY name ASC
```

---

### 3. 配置文件：告诉 Spring 数据库在哪里

```yaml
# 路径：payment-service/src/main/resources/application.yml

spring:
  datasource:
    url: jdbc:mysql://mysql-payment-service:3306/payment_db
    #              ↑ 数据库主机名         ↑ 端口   ↑ 数据库名
    username: root
    password: 12345
    driver-class-name: com.mysql.cj.jdbc.Driver
    
  jpa:
    hibernate:
      ddl-auto: update    # 启动时自动根据 Entity 更新表结构
      #         ↑ 选项：
      #         create  = 每次启动删表重建（丢数据！）
      #         update  = 有新字段就加上（不删旧的）
      #         validate = 只检查不修改
      #         none    = 什么都不做
    show-sql: true        # 在日志里打印执行的 SQL
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQLDialect
```

---

### 4. 关系映射：一对多

```java
// 路径：order-service/.../entity/Order.java

@Entity
@Table(name = "orders")
public class Order extends AbstractEntity {

    @Id
    private String id;

    // 一个订单有多个商品项
    @OneToMany(
        mappedBy = "order",           // OrderItem 里有个叫 order 的字段
        cascade = CascadeType.ALL,    // 保存 Order 时自动保存它的 Items
        fetch = FetchType.LAZY        // 不访问 orderItems 就不查询（优化）
    )
    private List<OrderItem> orderItems = new ArrayList<>();
}

// 路径：order-service/.../entity/OrderItem.java

@Entity
@Table(name = "order_items")
public class OrderItem extends AbstractEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne          // 多个 OrderItem 属于一个 Order
    @JoinColumn(name = "order_id")  // 外键列名
    private Order order;

    private String productId;
    private Integer quantity;
    private BigDecimal price;
}
```

**FetchType 非常重要！面试高频！**

```
LAZY（懒加载）：  访问 order.getOrderItems() 时才去查数据库
EAGER（饿加载）：  查 Order 时立刻把 OrderItems 也查出来

默认值：
  @OneToMany → LAZY（推荐）
  @ManyToOne → EAGER

问题：EAGER 会导致 N+1 问题（下面讲）
```

---

### 5. N+1 问题（面试必问）

```java
// 假设有 100 个订单

List<Order> orders = orderRepo.findAll();
// 执行 1 次 SQL：SELECT * FROM orders（拿到 100 个 Order）

for (Order order : orders) {
    System.out.println(order.getOrderItems().size());
    // 每个 Order 都触发一次 SQL：
    // SELECT * FROM order_items WHERE order_id = 1
    // SELECT * FROM order_items WHERE order_id = 2
    // ...
    // SELECT * FROM order_items WHERE order_id = 100
}

// 总共：1 + 100 = 101 次 SQL！这就是 N+1 问题

// 解决方案：JOIN FETCH 一次查出来
@Query("SELECT o FROM Order o JOIN FETCH o.orderItems")
List<Order> findAllWithItems();
// 只执行 1 次 SQL！性能差距可以是 100 倍！
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: JPA 和 Hibernate 是什么关系？**

> 🗣️ "JPA 是 Java 官方定义的持久化规范，只定义了接口和标准。
> Hibernate 是 JPA 的一个实现。Spring Boot 默认用的就是 Hibernate。
> Spring Data JPA 是在 Hibernate 之上再包一层，
> 让开发者通过方法名就能生成查询，不需要手写 SQL。"

---

**Q: 什么是 N+1 问题？怎么解决？**

> 🗣️ "当加载一个集合关联时，查主表是 1 次 SQL，
> 每条主记录关联的子记录又各查 1 次，共 N+1 次。
> 解决方案一是用 JOIN FETCH 在 JPQL 中一次性查出来；
> 二是用 @EntityGraph 指定预加载的属性；
> 三是用 @BatchSize 批量加载子记录。"

---

**Q: LAZY 和 EAGER 加载的区别？**

> 🗣️ "LAZY 是懒加载，只在访问关联字段时才查库，省内存但可能导致 N+1 问题。
> EAGER 是饿加载，主查询时立刻加载关联数据，
> 方便但可能加载大量不需要的数据。
> @OneToMany 默认 LAZY，@ManyToOne 默认 EAGER。
> 一般推荐统一用 LAZY，需要时通过 FETCH JOIN 主动加载。"

---

**Q: ddl-auto 的几个选项区别？**

> 🗣️ "create 每次启动删表重建，开发测试用；
> update 检查 Entity 和表结构差异，只增不删；
> validate 只验证不修改，生产用；
> none 什么都不做。
> 我们开发环境用 update 方便迭代，生产环境用 validate 或 none 配合 Flyway 管理。"

---

## ✅ 第四章检查清单

- [ ] 知道 JPA / Hibernate / Spring Data JPA 的关系
- [ ] 会看 Entity 类和数据库表的映射
- [ ] 理解 Repository 方法名怎么变成 SQL
- [ ] 知道 N+1 问题和解决方案
- [ ] 知道 LAZY vs EAGER 加载的区别

✅ 全部搞定 → 去看第五章（REST API）！



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
