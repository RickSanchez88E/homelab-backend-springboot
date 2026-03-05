# 第一章：Spring Boot 是什么？

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
> - "Spring Boot 解决了什么问题？"
> - "它跟我写过的 Java 有什么关系？"
> - "项目里的 main 方法在哪？"

---

## 📖 Part 1：从你懂的 Java 出发

### 你以前写 Java 会这样做：

想象你要写一个程序，让别人能通过浏览器访问，输入 `http://localhost:8080/hello`，
然后看到 "Hello World"。

**用原生 Java 你要做什么？**

```java
// 你需要手动处理 HTTP 请求
// 大概要写这么多（简化版）：

ServerSocket server = new ServerSocket(8080);
Socket socket = server.accept();
BufferedReader reader = new BufferedReader(
    new InputStreamReader(socket.getInputStream()));

// 读取 HTTP 请求头
String requestLine = reader.readLine(); // "GET /hello HTTP/1.1"
// 解析路径...
// 判断是不是 /hello...
// 手动拼接 HTTP 响应格式...

OutputStream output = socket.getOutputStream();
String response = "HTTP/1.1 200 OK\r\n\r\nHello World";
output.write(response.getBytes());
```

这还没完，你还要处理多个用户同时访问（多线程）、各种错误情况……
**一个 "Hello World" 就要写几百行！**

---

### Spring Boot 让你这样做：

```java
// 整个完整的 "Hello World" 服务！就这么多！

@RestController  // 告诉 Spring：这个类处理 HTTP 请求
public class HelloController {

    @GetMapping("/hello")  // 当有人访问 /hello 时
    public String hello() {
        return "Hello World";  // 直接返回字符串，Spring 自动处理 HTTP
    }
}
```

**Spring Boot 帮你做了：**
- 启动 HTTP 服务器（内置 Tomcat）
- 接收请求、解析路径
- 调用对应方法
- 把返回值转成 HTTP 响应

你只需要写**业务逻辑**（我想干什么），不用管**基础设施**（怎么接收请求）。

---

## 💻 Part 2：在这个项目里怎么用？

### 找到项目的 main 方法

每个 Spring Boot 应用都有一个入口。打开这个文件：

```
payment-service/
  src/main/java/net/javaguides/payment_service/
    PaymentServiceApplication.java  ← 就是这里！
```

```java
package net.javaguides.payment_service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication  // ← 这一个注解顶一万行配置
public class PaymentServiceApplication {

    // 就是你熟悉的 main 方法！
    public static void main(String[] args) {
        SpringApplication.run(PaymentServiceApplication.class, args);
        // 这句话做了什么：
        // 1. 启动内置的 Tomcat 服务器（你不用安装 Tomcat）
        // 2. 扫描所有 @Controller, @Service, @Repository 注解
        // 3. 把它们全部创建好，放进一个大容器
        // 4. 等着接收 HTTP 请求
    }
}
```

### `@SpringBootApplication` 这一个注解做了什么？

```
@SpringBootApplication
= @Configuration       // "这个类里面有配置"
+ @EnableAutoConfiguration  // "自动帮我配置各种东西"（数据库、Redis 等）
+ @ComponentScan       // "扫描这个包下所有的 @Component 注解"
```

**用人话说：** 就是告诉 Spring：
1. 去找所有带了特殊注解的类
2. 自动帮我配置好数据库连接、HTTP 服务器等
3. 启动！

---

### 看看 payment-service 的 Controller（处理 HTTP 请求的地方）

```
payment-service/src/main/java/.../controller/PaymentController.java
```

```java
@RestController
@RequestMapping("/api/v1/payments")  // 这个 Controller 处理 /api/v1/payments 开头的请求
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    // 当用户发 GET 请求到 /api/v1/payments/{orderId} 时
    @GetMapping("/{orderId}")
    public ResponseEntity<?> getPaymentByOrderId(@PathVariable String orderId) {
        return ResponseEntity.ok(paymentService.getPaymentByOrderId(orderId));
    }

    // 当用户发 PUT 请求到 /api/v1/payments/refund/{paymentId} 时
    @PutMapping("/refund/{paymentId}")
    public ResponseEntity<?> refundPayment(@PathVariable String paymentId) {
        paymentService.refundPayment(paymentId);
        return ResponseEntity.ok("Refund successful");
    }
}
```

**对比你知道的 Java：**
- `@RestController` = 这个类是 HTTP 请求处理器
- `@GetMapping("/hello")` = 处理 GET 请求到 /hello 路径
- `@PathVariable` = 从 URL 里取值（`/payments/abc123` → `orderId = "abc123"`）

---

### 项目的文件夹结构（非常重要！每个服务都一样）

```
payment-service/
├── src/main/java/net/javaguides/payment_service/
│   ├── PaymentServiceApplication.java  ← 入口（main方法）
│   ├── controller/                     ← 接收 HTTP 请求
│   │   └── PaymentController.java
│   ├── service/                        ← 业务逻辑
│   │   ├── PaymentService.java         （接口）
│   │   └── impl/
│   │       └── PaymentServiceImpl.java （实现）
│   ├── repository/                     ← 操作数据库
│   │   └── PaymentRepository.java
│   ├── entity/                         ← 数据库表对应的 Java 类
│   │   └── Payment.java
│   ├── dto/                            ← 用来传数据的类（不是数据库表）
│   │   └── PaymentDTO.java
│   └── config/                         ← 各种配置（Kafka、Redis 等）
└── src/main/resources/
    └── application.yml                 ← 配置文件（数据库地址、端口等）
```

这个结构叫做**三层架构**，是 Spring Boot 项目的标准结构，下一章详细讲。

---

## 🧠 Part 2.5：项目里用到的 Java 语法速查（很重要！）

> 下面这些语法在项目**每个文件**都出现，看不懂就没法读代码。
> 如果你都记得，跳过这节；忘了就仔细看。

### 1. 泛型 Generics — `<T>`, `<?>`, `<String>`

**泛型是什么？** 给类加一个"类型参数"，编译器帮你检查类型安全。

```java
// ——— 你肯定用过的 ArrayList ———

// ❌ 不用泛型：什么都能放，取出来要强转，容易炸
ArrayList list = new ArrayList();
list.add("hello");
list.add(123);                    // 不报错！但类型混乱
String s = (String) list.get(1);  // 💥 运行时 ClassCastException！

// ✅ 用泛型：限定只能放 String
ArrayList<String> list = new ArrayList<>();
list.add("hello");
list.add(123);  // ❌ 编译器直接报错！不让你放 int
String s = list.get(0);  // ✅ 不需要强转，编译器知道一定是 String
```

**项目里的泛型用法：**

```java
// ——— ResponseEntity<T> ———
// Spring 的 HTTP 响应包装类，T 就是 body 的类型

ResponseEntity<String>     // body 一定是 String
ResponseEntity<Payment>    // body 一定是 Payment 对象
ResponseEntity<?>          // body 可以是任何类型（通配符）

// 为什么项目里用 <?> ？因为同一个方法可能返回不同类型：
@GetMapping("/{orderId}")
public ResponseEntity<?> getPaymentByOrderId(@PathVariable String orderId) {
    // 成功时 → 返回 Payment 对象
    // 失败时 → 可能返回 String 错误信息
    // 所以用 <?> 表示"我不限定返回什么类型"
    return ResponseEntity.ok(paymentService.getPaymentByOrderId(orderId));
}

// ResponseEntity.ok(...) 的意思：
// = new ResponseEntity<>(数据, HttpStatus.OK)
// = 返回 HTTP 200 状态码 + body 数据
```

**泛型符号总结（面试常考）：**

```java
<T>              // 定义时用："这里有个类型参数叫 T"
<String>         // 使用时用："T 是 String"
<?>              // 使用时用："T 是什么我不关心"，通配符
<? extends T>    // "只能是 T 或 T 的子类"（上界）
<? super T>      // "只能是 T 或 T 的父类"（下界）

// 面试关键一句话：
// "Java 泛型是编译时的类型检查，运行时会被擦除（Type Erasure）"
// 意思是：ArrayList<String> 编译后变成 ArrayList，泛型信息消失了
```

---

### 2. Lombok 注解 — 项目里几乎每个类都用

**Lombok 是什么？** 一个帮你自动生成代码的工具，减少样板代码。

```java
// ——— @Data ———
// 自动生成：getter, setter, toString, equals, hashCode

// ❌ 不用 Lombok 你要写这么多：
public class Payment {
    private String id;
    private Double amount;
    
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public String toString() { return "Payment(id=" + id + ", amount=" + amount + ")"; }
    public boolean equals(Object o) { ... }
    public int hashCode() { ... }
}

// ✅ 用 @Data 一个注解搞定：
@Data  // 自动生成上面所有方法！
public class Payment {
    private String id;
    private Double amount;
}
```

```java
// ——— @RequiredArgsConstructor ———
// 自动生成一个构造方法，参数是所有 final 字段

// 项目里的 PaymentController 写了这个：
@RestController
@RequiredArgsConstructor  // ← 这个注解
public class PaymentController {
    private final PaymentService paymentService;  // ← final 字段
}

// Lombok 自动帮你生成了：
public PaymentController(PaymentService paymentService) {
    this.paymentService = paymentService;
}

// 为什么不手写构造方法？
// Spring 看到只有一个构造方法 → 自动把 PaymentService 注入进来
// 这就是"构造器注入"，Spring 推荐的方式
// 所以 @RequiredArgsConstructor + private final 字段 = 依赖注入
```

```java
// ——— 其他常用 Lombok 注解 ———

@Getter          // 只生成 getter（不生成 setter）
@Setter          // 只生成 setter
@NoArgsConstructor  // 生成无参构造 public Payment() {}
@AllArgsConstructor // 生成全参构造 public Payment(String id, Double amount) {}
@Builder         // 生成 Builder 模式（后面讲）
```

---

### 3. Optional — 解决空指针

```java
// ——— 项目里 Repository 经常返回 Optional ———

// 项目代码（payment-service）：
public interface PaymentRepository extends JpaRepository<Payment, String> {
    Optional<Payment> findByOrderId(String orderId);
    //       ↑ 表示"可能有值，也可能没有"
}

// ❌ 不用 Optional（传统写法）：
Payment payment = paymentRepo.findByOrderId("abc123");
if (payment == null) {  // 如果忘了检查 → NullPointerException 💥
    throw new RuntimeException("Not found");
}
String id = payment.getId();

// ✅ 用 Optional（项目里的写法）：
Payment payment = paymentRepo.findByOrderId("abc123")
    .orElseThrow(() -> new RuntimeException("Payment not found"));
//   ↑ 如果有值 → 直接返回 Payment
//   ↑ 如果没有 → 自动抛异常

// Optional 常用方法：
optional.isPresent()          // 有值吗？true/false
optional.get()                // 取值（不安全，可能报错）
optional.orElse(默认值)        // 有值就取，没有就用默认值
optional.orElseThrow(异常)    // 有值就取，没有就抛异常 ← 项目最常用
optional.map(x -> ...)        // 有值的话做转换

// 这里的 () -> 是 Lambda 表达式，下面讲 ↓
```

---

### 4. Lambda 表达式 — `->` 箭头写法

```java
// Lambda 就是"匿名函数"的简写

// ❌ 传统写法（匿名内部类）：
Runnable task = new Runnable() {
    @Override
    public void run() {
        System.out.println("Hello");
    }
};

// ✅ Lambda 简写：
Runnable task = () -> System.out.println("Hello");
// () 是参数列表（这里没参数）
// -> 表示"执行"
// 右边是方法体

// 项目里的用法：
.orElseThrow(() -> new RuntimeException("Not found"))
//             ↑ 无参数 → 执行 → 创建一个异常

// Stream API 里也大量使用：
List<String> names = users.stream()
    .map(user -> user.getName())    // 每个 user → 取出 name
    .filter(name -> name != null)   // 只保留不为 null 的
    .collect(Collectors.toList());  // 收集成 List
```

---

### 5. `@PathVariable` 和 `@RequestBody` — 从请求取数据

```java
// 项目里的 PaymentController：

// @PathVariable — 从 URL 路径取值
@GetMapping("/{orderId}")
public ResponseEntity<?> getPaymentByOrderId(@PathVariable String orderId) { ... }
// 请求：GET /api/v1/payments/abc123
// orderId 自动变成 "abc123"

// @RequestBody — 从请求 Body 取 JSON，自动转成 Java 对象
// 项目里 identity-service 的 AuthController：
@PostMapping("/register")
public ResponseEntity<ApiResponse<String>> addNewUser(@RequestBody SignUpRequest signUpRequest) { ... }
// 请求：POST /api/v1/auth/register
// Body: {"name":"Test User","email":"test@example.com","password":"123"}
// Spring 自动把 JSON → SignUpRequest 对象：
//   signUpRequest.getName() = "Test User"
//   signUpRequest.getEmail() = "test@example.com"
//   signUpRequest.getPassword() = "123"

// @RequestParam — 从 URL 参数取值
@GetMapping("/validate")
public ResponseEntity<?> validateToken(@RequestParam("token") String token) { ... }
// 请求：GET /api/v1/auth/validate?token=eyJhbGciOiJ...
// token 自动变成 "eyJhbGciOiJ..."
```

---

### 6. `private final` — 为什么字段要加 final？

```java
@Service
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {
    private final PaymentRepository paymentRepository;  // ← final
    private final OrderProducer orderProducer;           // ← final
    private final PaymentRedis paymentRedis;             // ← final
}

// 为什么用 private final？
// 1. private → 外部不能直接访问（封装）
// 2. final   → 一旦赋值就不能改（不可变，线程安全）
// 3. final 字段只能通过构造方法赋值
// 4. @RequiredArgsConstructor 会为所有 final 字段生成构造方法
// 5. Spring 自动调用这个构造方法，把依赖注入进来

// 等效于：
public PaymentServiceImpl(PaymentRepository paymentRepository,
                          OrderProducer orderProducer,
                          PaymentRedis paymentRedis) {
    this.paymentRepository = paymentRepository;  // Spring 自动传入
    this.orderProducer = orderProducer;           // Spring 自动传入
    this.paymentRedis = paymentRedis;             // Spring 自动传入
}
```

---

### 7. 接口 + 实现 — 为什么 Service 要拆成接口和 Impl？

```java
// 项目里你会看到 Service 都这样拆：
// PaymentService.java ← 接口（定义"能做什么"）
// PaymentServiceImpl.java ← 实现类（定义"怎么做"）

// 接口：
public interface PaymentService {
    Payment getPaymentByOrderId(String orderId);
    void refundPayment(String paymentId);
}

// 实现：
@Service  // 告诉 Spring：这个是真正干活的
public class PaymentServiceImpl implements PaymentService {
    @Override
    public Payment getPaymentByOrderId(String orderId) {
        // 具体的业务逻辑...
    }
}

// 为什么要拆开？（面试必问）
// 1. 解耦：Controller 只依赖接口，不关心具体实现
// 2. 可测试：测试时可以用 Mock 替换真实实现
// 3. 可替换：比如支付换成微信支付，只改 Impl 不改接口
// 4. Spring AOP 需要接口来创建代理（事务、缓存等）
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: 介绍一下你用 Spring Boot 做了什么项目？**

> 🗣️ 你的答法（用这段话）：
>
> "我实践了一个基于 Spring Boot 的微服务电商项目。
> 项目拆分成了 7 个独立服务：商品、订单、支付、邮件、身份认证、API 网关，
> 还有一个服务注册中心。
> 每个服务都是独立的 Spring Boot 应用，有自己的数据库，
> 服务之间的异步通信通过 Apache Kafka 实现。"

---

**Q: Spring Boot 和 Spring 有什么区别？**

> 🗣️ 你的答法：
>
> "Spring 是框架本身，功能强大但配置复杂，需要大量 XML 配置文件。
> Spring Boot 是 Spring 的升级版，核心是'约定大于配置'——
> 它帮你做了大量默认配置，让你能快速启动项目，
> 不需要写一堆配置文件。
> 比如我这个项目，每个服务的 main 方法只有三行，
> 剩下的数据库连接、HTTP 服务器都是 Spring Boot 自动配置的。"

---

**Q: `@SpringBootApplication` 这个注解是做什么的？**

> 🗣️ 你的答法：
>
> "这是一个组合注解，等于同时加了三个注解：
> @Configuration 说明这是配置类，
> @EnableAutoConfiguration 启用自动配置，
> @ComponentScan 让 Spring 自动找到带注解的类并管理它们。
> 简单说，就是一键启动 Spring Boot 应用的开关。"

---

## ✅ 第一章检查清单

学完这章，你应该能回答：

- [ ] Spring Boot 解决了什么问题？（答：简化配置，让你专注业务逻辑）
- [ ] 项目里 main 方法在哪？（答：XxxApplication.java 里）
- [ ] `@SpringBootApplication` 是什么？（答：三合一注解，启动 Spring 容器）
- [ ] 看到 `@RestController` 知道它是做什么的？（答：处理 HTTP 请求的类）

✅ 全部能回答 → 去看第二章！



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
