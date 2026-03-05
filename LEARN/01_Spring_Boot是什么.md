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
