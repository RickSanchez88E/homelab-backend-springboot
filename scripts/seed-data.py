#!/usr/bin/env python3
"""数据填充 + 压力测试工具"""

import subprocess, sys, time, random, string, os

LEVEL = sys.argv[1] if len(sys.argv) > 1 else "small"

CONFIGS = {
    "small":  {"products": 1000,    "reviews": 5000},
    "medium": {"products": 100000,  "reviews": 500000},
    "large":  {"products": 1000000, "reviews": 5000000},
}

if LEVEL not in CONFIGS:
    print("用法: python3 scripts/seed-data.py [small|medium|large]")
    sys.exit(1)

cfg = CONFIGS[LEVEL]
print(f"🏭 数据填充: {LEVEL} 级别")
print(f"  Products: {cfg['products']:,}")
print(f"  Reviews:  {cfg['reviews']:,}")
print()

BATCH = 1000  # 每个 INSERT 多少行

def generate_sql(table_db, table, columns, row_gen, total, container):
    """生成批量 INSERT SQL 并导入"""
    tmpfile = f"/tmp/seed_{table}.sql"
    with open(tmpfile, "w") as f:
        f.write("SET autocommit=0;\n")
        for start in range(0, total, BATCH):
            end = min(start + BATCH, total)
            f.write(f"INSERT INTO {table} ({','.join(columns)}) VALUES\n")
            rows = []
            for i in range(start, end):
                rows.append(f"({row_gen(i)})")
            f.write(",\n".join(rows))
            f.write(";\nCOMMIT;\n")
        f.write("SET autocommit=1;\n")

    size = os.path.getsize(tmpfile) / 1024 / 1024
    print(f"  📄 SQL 文件: {size:.1f} MB")

    # 复制到容器并执行
    subprocess.run(["docker", "cp", tmpfile, f"{container}:/tmp/seed.sql"],
                   capture_output=True)
    t0 = time.time()
    subprocess.run(
        ["docker", "exec", container, "mysql", "-uroot", "-proot", table_db,
         "-e", "source /tmp/seed.sql"],
        capture_output=True, text=True
    )
    elapsed = time.time() - t0

    # 统计
    result = subprocess.run(
        ["docker", "exec", container, "mysql", "-uroot", "-proot", "-N",
         "-e", f"SELECT COUNT(*) FROM {table_db}.{table}"],
        capture_output=True, text=True
    )
    count = result.stdout.strip()
    print(f"  ✅ {count} 条 ({elapsed:.1f}s)")

# --- 商品数据 ---
print("📦 填充商品数据...")
COMMENTS_ZH = [
    "京东自营正品保障", "年度爆款热销商品", "限时特价优惠中",
    "新品上架品质之选", "会员专享折扣商品", "厂家直供价格实惠",
    "品牌旗舰店正品", "满减优惠叠加使用", "配送快次日达",
    "好评率99%畅销品"
]
def prod_row(i):
    price = round(random.uniform(9.9, 9999.99), 2)
    discount = round(random.uniform(0, 0.5), 2)
    desc = random.choice(COMMENTS_ZH)
    return f"UUID(),'Product-{i:07d}','{desc}',{price},{discount},'https://via.placeholder.com/200',0,NOW(),NOW()"

generate_sql("product_db", "products",
             ["id", "name", "description", "price", "discount", "image_url", "version", "created_at", "updated_at"],
             prod_row, cfg["products"], "mysql-product-service")

# --- 评价数据 ---
print("⭐ 填充评价数据...")
REVIEW_TEXTS = [
    "非常好用强烈推荐", "质量不错物流很快", "一般般还行吧",
    "性价比很高会回购", "包装精美送人很合适", "京东自营品质有保障",
    "比实体店便宜很多", "客服态度很好", "已经回购第三次了",
    "朋友推荐的确实不错", "发货速度快隔天就到", "颜色很正很喜欢"
]
def review_row(i):
    text = random.choice(REVIEW_TEXTS)
    days = random.randint(0, 365)
    return f"UUID(),'Review-{i:07d}','{text}',DATE_SUB(NOW(),INTERVAL {days} DAY)"

generate_sql("review_db", "reviews",
             ["id", "name", "description", "created_at"],
             review_row, cfg["reviews"], "mysql-product-service")

print()
print("=" * 50)
print("✅ 数据填充完成！")
print("=" * 50)
