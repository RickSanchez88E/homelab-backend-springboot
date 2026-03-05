# 第三章：依赖注入（DI）和控制反转（IoC）—— Spring 最核心的概念

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
> - "什么是依赖注入？解决了什么问题？"
> - "IoC 容器是什么？"
> - "为什么不直接 new 一个对象？"
> - "构造器注入和 @Autowired 有什么区别？"
>
> ⚠️ **这是 Spring 面试最高频的题！100% 会问！**

---

## 📖 Part 1：从你懂的 Java 出发

### 你以前怎么用一个对象？

```java
// 你学 OOP 时就是这么做的：
public class OrderService {
    
    public void createOrder() {
        // 需要用数据库操作？直接 new 一个！
        OrderRepository repo = new OrderRepository();
        
        // 需要发 Kafka 消息？直接 new 一个！
        KafkaProducer producer = new KafkaProducer();
        
        // 需要查商品信息？直接 new 一个！
        ProductClient client = new ProductClient();
        
        // ... 然后开始写业务逻辑
    }
}
```

**这叫做"你自己控制对象的创建"。有什么问题？**

---

### 问题一：换一个实现怎么办？

```java
// 开发时用假的发送器（不真的发邮件）
EmailSender sender = new FakeEmailSender();

// 上线时要改成真的发送器
EmailSender sender = new RealEmailSender();

// 问题：你要找到所有写了 new FakeEmailSender() 的地方，一个个改！
// 如果 100 个地方都用到了呢？改漏一个就出 bug！
```

### 问题二：测试困难

```java
// 你想测试 OrderService 的逻辑，但是一 new 就连数据库了
// 测试还没开始，数据库挂了 → 测试失败
// 你想测的是业务逻辑，不是数据库连接！
```

### 问题三：对象创建可能很复杂

```java
// 创建一个数据库连接可能需要：
DataSource ds = new HikariDataSource();
ds.setJdbcUrl("jdbc:mysql://localhost:3306/mydb");
ds.setUsername("root");
ds.setPassword("password");
ds.setMaximumPoolSize(20);
ds.setMinimumIdle(5);
// ... 还有一堆参数

// 每次 new 都要写这一堆？不可能吧！
```

---

### 解决方案：让别人帮你创建，你只管用

**这就是控制反转（IoC）和依赖注入（DI）的核心思想。**

**控制反转（Inversion of Control）：**
- 以前：你自己 `new` 对象（你控制对象的创建）
- 现在：Spring 帮你创建好，需要的时候直接给你（控制权反转给了 Spring）

**依赖注入（Dependency Injection）：**
- "依赖" = 你的类需要用到的其他对象
- "注入" = Spring 把这些对象塞给你

```
以前你自己做的事：
  OrderService 需要 repository → 自己 new Repository()

现在 Spring 做的事：
  Spring 看到你需要 repository → Spring 去创建它 → Spring 塞给你
  你只需要说 "我需要一个 Repository" 就行
```

---

## 💻 Part 2：在这个项目里怎么用？

### 方式一：构造器注入（本项目最主要的方式）

```
路径：payment-service/src/main/java/.../service/impl/PaymentServiceImpl.java
```

```java
@Service                    // ① 告诉 Spring：这个类交给你管理
@RequiredArgsConstructor    // ② Lombok 自动生成构造方法
public class PaymentServiceImpl implements PaymentService {

    // ③ 声明"我需要这些对象"（注意是 final）
    private final PaymentRepository paymentRepo;
    private final PaymentRedis paymentRedis;
    
    // Lombok 帮你生成的代码等同于：
    // public PaymentServiceImpl(PaymentRepository paymentRepo, 
    //                           PaymentRedis paymentRedis) {
    //     this.paymentRepo = paymentRepo;
    //     this.paymentRedis = paymentRedis;
    // }
    
    // ④ 你直接用就行，不需要 new！
    public Payment getPaymentByOrderId(String orderId) {
        return paymentRepo.findByOrderId(orderId).orElseThrow();
        //     ↑ 这个对象是 Spring 塞进来的，不是你 new 的
    }
}
```

**Spring 在背后做了什么？**

```
应用启动时：
1. Spring 扫描到 @Service → "我要管理 PaymentServiceImpl"
2. 发现它需要 PaymentRepository 和 PaymentRedis
3. 先创建 PaymentRepository（它是 @Repository）
4. 先创建 PaymentRedis（它是 @Component）
5. 用它们的构造方法创建 PaymentServiceImpl
6. 把这个 PaymentServiceImpl 实例存起来

有人需要 PaymentService 时：
1. Spring 从容器里找到 PaymentServiceImpl
2. 直接给它
```

---

### IoC 容器是什么？

打个比方：

```
你以前：
  自己去超市买菜 → 自己洗菜 → 自己做饭
  （自己 new 对象 → 自己传参数 → 自己管理生命周期）

Spring IoC 容器：
  你告诉食堂 "我要一份鱼香肉丝"
  食堂帮你准备好 → 直接端给你
  
IoC 容器 = Spring 内部的一个大仓库
  里面存着所有被 @Service @Repository @Component 标记的对象实例
  这些实例叫做 "Bean"（豆子）
  需要的时候从仓库里取出来用
```

---

### 方式二：@Autowired 字段注入（不推荐但面试会问）

```java
// ❌ 字段注入 —— 能用，但不推荐
@Service
public class PaymentServiceImpl {
    @Autowired          // Spring 直接把对象注入到这个字段
    private PaymentRepository paymentRepo;
}

// ✅ 构造器注入 —— 推荐（本项目用的方式）
@Service
@RequiredArgsConstructor
public class PaymentServiceImpl {
    private final PaymentRepository paymentRepo;  // final = 不能改
}
```

**为什么构造器注入更好？**

```
① 安全性：final 保证赋值后不能修改
② 清晰性：一看构造方法就知道这个类依赖什么
③ 测试性：不需要 Spring 容器，直接 new 传参就能测试
   
   // 单元测试时：
   PaymentRepository mockRepo = mock(PaymentRepository.class);
   PaymentServiceImpl service = new PaymentServiceImpl(mockRepo, mockRedis);
   // 不需要启动 Spring！

④ 循环依赖：构造器注入在启动时就会报错，字段注入可能潜伏到运行时
```

---

### 看看 IoC 全链路：从启动到注入

```
Spring Boot 启动
    ↓
@SpringBootApplication 里的 @ComponentScan 开始扫描
    ↓
扫描到所有带注解的类：
    @RestController PaymentController  → 注册为 Bean
    @Service PaymentServiceImpl        → 注册为 Bean
    @Repository PaymentRepository      → 注册为 Bean
    @Component PaymentRedis            → 注册为 Bean
    ↓
分析依赖关系：
    PaymentController 需要 PaymentService
    PaymentServiceImpl 需要 PaymentRepository 和 PaymentRedis
    ↓
按依赖顺序创建实例：
    1. 先创建 PaymentRepository（没有依赖）
    2. 再创建 PaymentRedis（没有依赖）
    3. 再创建 PaymentServiceImpl（传入 1 和 2）
    4. 最后创建 PaymentController（传入 3）
    ↓
全部创建完毕，放入 IoC 容器
    ↓
等待请求...
```

---

### Bean 默认是单例！

```java
@Service
public class PaymentServiceImpl { ... }

// Spring 只会创建 这个类的一个实例
// 所有用到它的地方，拿到的都是同一个对象

// 为什么？
// - 节省内存（不是每个请求都创建新对象）
// - 这些类通常没有状态（不存用户数据），只有方法，所以共享是安全的

// 如果你需要每次都创建新的（极少见）：
@Scope("prototype")
@Service
public class SomeSpecialService { ... }
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: 什么是 IoC 和 DI？**

> 🗣️ 你的答法：
>
> "IoC 是控制反转，意思是把对象的创建和管理权从我们自己的代码
> 交给了 Spring 框架。以前是我们手动 new 对象，
> 现在是 Spring 帮我们创建并注入。
> DI 是依赖注入，是 IoC 的具体实现方式。
> 我的类需要哪些对象，在构造方法的参数里声明，
> Spring 启动时自动创建并传给我。
> 在我的项目里，所有 Service 和 Controller 都用 Lombok 的
> @RequiredArgsConstructor 来做构造器注入。"

---

**Q: 为什么推荐构造器注入而不用 @Autowired？**

> 🗣️ 你的答法：
>
> "三个原因：第一，字段可以用 final 修饰，保证不被意外修改；
> 第二，从构造方法就能清楚看到这个类的所有依赖；
> 第三，方便单元测试，不需要启动 Spring 容器就能通过构造方法传入 mock 对象。
> 另外构造器注入还能在启动时就发现循环依赖问题。"

---

**Q: Spring Bean 的默认作用域是什么？**

> 🗣️ 你的答法：
>
> "默认是 singleton，即单例。整个 Spring 容器中只有一个实例。
> 这对于无状态的 Service、Repository 是安全的，因为它们只有方法没有用户数据。
> 如果需要每次都创建新的实例，可以用 @Scope('prototype')。"

---

**Q: Spring 是怎么知道要注入哪个实现类的？**

> 🗣️ 你的答法：
>
> "Spring 按类型匹配。如果我声明了 `private final PaymentService paymentService`，
> Spring 会去容器里找所有 PaymentService 接口的实现类。
> 如果只有一个实现类 PaymentServiceImpl，就直接注入。
> 如果有多个实现类，就需要用 @Qualifier 注解指定用哪一个，
> 或者在某个实现类上加 @Primary 表示它是默认的。"

---

## ✅ 第三章检查清单

- [ ] 能用自己的话解释 IoC 和 DI 的区别
- [ ] 知道为什么不直接 new 对象
- [ ] 能说出构造器注入的三个优点
- [ ] 知道 Bean 默认是单例的
- [ ] 知道 @Service / @Repository / @Component 都是 Bean

✅ 全部搞定 → 去看第四章（数据库与 JPA）！



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
