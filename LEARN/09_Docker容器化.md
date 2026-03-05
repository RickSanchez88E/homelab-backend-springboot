# 第九章：Docker 容器化 —— 一键启动整个系统

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
> - "Docker 是什么？解决了什么问题？"
> - "Dockerfile 和 docker-compose 是什么关系？"
> - "你的项目怎么用 Docker 部署的？"
>
> ⚠️ JD 要求 "familiar with basic system operations"，Docker 是基础！

---

## 📖 Part 1：从你懂的 Java 出发

### 没有 Docker 时的痛苦

```
你写好了这个项目，想给同事跑一下：

你：代码在 GitHub，你 clone 下来就能跑

同事花了 2 小时尝试：
  ❌ "我的 Java 版本是 11，你要 17"
  ❌ "我没装 MySQL"
  ❌ "我的 MySQL 版本不一样，SQL 语法不兼容"
  ❌ "我没装 Kafka"
  ❌ "我没装 Redis"
  ❌ "你的端口 8080 我已经被其他程序占了"
  ❌ "我是 Windows，你的脚本在 Mac 上才能跑"

你：在我电脑上是好的啊…… 🤷

这就是经典的 "It works on my machine" 问题
```

---

### Docker 怎么解决的？

```
Docker = 把你的程序 + 它需要的所有环境打包成一个"容器"

类比：
  没有 Docker：
    搬家时要自己搬沙发、电视、冰箱…… 到新家还得重新布置
    
  有了 Docker：
    把整个房间打包（包括家具、电器、装修）→ 搬到哪里都一样

容器 = 一个独立的、隔离的运行环境
  里面有 Java 17、你的 JAR、需要的配置
  不管宿主机装的什么系统，容器内部的环境永远一样
```

---

## 💻 Part 2：在这个项目里怎么用？

### 1. Dockerfile：怎么打包一个服务

```dockerfile
# 路径：payment-service/Dockerfile

# 基础镜像：一个已经装好 Java 17 的精简 Linux 系统
FROM eclipse-temurin:17-jre
#    ↑ 就像说"给我一台已经装好 Java 的电脑"

# 设置工作目录
WORKDIR /app
# ↑ 进入 /app 目录（没有就创建）

# 把编译好的 JAR 复制进去
COPY target/payment-service.jar /app/payment-service.jar
# ↑ 把你本地 target/ 下的 JAR 放到容器里

# 声明端口
EXPOSE 8083
# ↑ 告诉别人这个容器用 8083 端口

# 启动命令
ENTRYPOINT ["java", "-jar", "payment-service.jar"]
# ↑ 容器启动时执行这个命令（运行你的 Spring Boot 应用）
```

**过程：**
```
你的 Java 代码
    ↓ mvn clean package（编译打包）
target/payment-service.jar（可执行的 JAR）
    ↓ docker build（根据 Dockerfile 打包）
Docker 镜像（Image）= Linux + Java + 你的 JAR
    ↓ docker run（运行镜像）
Docker 容器（Container）= 一个正在运行的实例
```

---

### 2. 镜像 vs 容器

```
镜像（Image）= 蛋糕模具
  只是一个模板，不能运行
  可以从一个镜像创建多个容器

容器（Container）= 用模具做出来的蛋糕  
  正在运行的实例
  可以启动、停止、删除
  
类比：
  镜像 = 一个 Java 类（class）
  容器 = 一个对象（new 出来的实例）
```

---

### 3. docker-compose：一键启动所有服务

```
问题：
  你的项目有 7 个微服务 + MySQL × 4 + Redis + Kafka + Zookeeper
  = 14 个容器！

  手动一个个启动？疯了！

docker-compose = 用一个文件描述所有容器，一条命令全部启动
```

```yaml
# docker-compose.yml（简化版，看关键部分）

services:

  # ======== 基础设施 ========
  
  # 数据库
  mysql-order-service:
    image: mysql:latest           # 用官方 MySQL 镜像
    environment:
      MYSQL_ROOT_PASSWORD: 12345  # 数据库密码
      MYSQL_DATABASE: order_db    # 自动创建的数据库名
    ports:
      - "3307:3306"               # 主机的 3307 → 容器的 3306
    volumes:
      - mysql-order-data:/var/lib/mysql  # 数据持久化！
    #   ↑ 容器删除后数据还在（不然删容器 = 删数据）

  # Redis 缓存
  redis:
    image: redis:latest
    ports:
      - "6379:6379"

  # Kafka 消息队列
  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper                 # Kafka 依赖 Zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092

  # ======== 微服务 ========
  
  # 服务注册中心（第一个启动！）
  eureka-server:
    build:
      context: ./service-registry  # 从这个目录的 Dockerfile 构建
    ports:
      - "8761:8761"

  # API 网关（等 Eureka 起来后再启动）
  api-gateway:
    build:
      context: ./api-gateway
    ports:
      - "8080:8080"
    depends_on:
      - eureka-server              # 依赖 Eureka
    environment:
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka/

  # 订单服务
  order-service:
    build:
      context: ./order-service
    depends_on:
      - mysql-order-service        # 依赖数据库
      - kafka                      # 依赖 Kafka
      - eureka-server              # 依赖注册中心
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql-order-service:3306/order_db
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
```

**关键概念：**

```
depends_on: 启动顺序
  eureka-server 先启动
  → 然后启动 api-gateway, order-service 等

ports: "主机端口:容器端口"
  "8080:8080" 意思是访问你电脑的 8080 → 转到容器的 8080

environment: 环境变量，覆盖 application.yml 里的配置
  容器内不写死地址，用环境变量传入

volumes: 数据持久化
  没有 volumes：删容器 → 数据全丢
  有 volumes：数据存在宿主机的磁盘上 → 容器删了数据还在

networks: 容器间的网络
  同一个 network 里的容器可以用服务名互相访问
  order-service 可以用 "mysql-order-service:3306" 访问数据库
  不需要知道 IP 地址！
```

---

### 4. 常用 Docker 命令

```bash
# 启动所有服务（后台运行）
docker-compose up -d --build

# 查看所有容器状态
docker-compose ps

# 查看某个服务的日志
docker-compose logs -f order-service
#                   ↑ -f 表示实时跟踪

# 停止所有服务
docker-compose down

# 停止并删除卷（⚠️ 会删数据！）
docker-compose down -v

# 重新构建某个服务
docker-compose build order-service

# 进入容器内部
docker exec -it order-service bash
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: 你的项目是怎么部署的？**

> 🗣️ "用 Docker 容器化部署。每个微服务有自己的 Dockerfile，
> 基于 eclipse-temurin:17-jre 镜像，把编译好的 JAR 包复制进去。
> 用 docker-compose 编排所有服务，包括 7 个微服务
> 和基础设施（4个MySQL、Redis、Kafka、Zookeeper），
> 一条 docker-compose up 命令就能启动整个系统。"

---

**Q: Docker Image 和 Container 的区别？**

> 🗣️ "Image 是只读的模板，包含运行应用所需的所有文件和配置。
> Container 是 Image 的运行实例，可以启动、停止、删除。
> 一个 Image 可以创建多个 Container。
> 类比的话，Image 像 Java 的 Class，Container 像 new 出来的对象。"

---

**Q: docker-compose 的 depends_on 能保证服务完全启动吗？**

> 🗣️ "不能。depends_on 只保证启动顺序，不保证服务 ready。
> 比如 MySQL 容器启动了但数据库初始化还没完成，
> order-service 就已经开始连接了，可能报错。
> 解决方案是在 Spring Boot 里配置重试机制，
> 或者在 docker-compose 里用 healthcheck 加 condition。"

---

## ✅ 第九章检查清单

- [ ] 知道 Docker 解决了什么问题
- [ ] 能看懂 Dockerfile 每一行的含义
- [ ] 理解 Image vs Container
- [ ] 能看懂 docker-compose.yml 的核心配置
- [ ] 知道 volumes 是做什么的（数据持久化）

✅ 全部搞定 → 去看第十章（面试模拟）！



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
