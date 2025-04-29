-- 创建业务数据表

-- 客户表
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_login_date TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 产品类别表
CREATE TABLE product_categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    parent_category_id INTEGER REFERENCES product_categories(category_id)
);

-- 产品表
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES product_categories(category_id),
    price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2),
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 订单表
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    shipping_address VARCHAR(200),
    shipping_city VARCHAR(50),
    shipping_country VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_method VARCHAR(50),
    payment_method VARCHAR(50),
    total_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    shipping_amount DECIMAL(10, 2) DEFAULT 0
);

-- 订单项目表
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_percent DECIMAL(5, 2) DEFAULT 0
);

-- 库存表
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    warehouse_id INTEGER,
    quantity INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 营销活动表
CREATE TABLE marketing_campaigns (
    campaign_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'planned'
);

-- 营销活动结果表
CREATE TABLE campaign_results (
    result_id SERIAL PRIMARY KEY,
    campaign_id INTEGER REFERENCES marketing_campaigns(campaign_id),
    date DATE NOT NULL,
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    revenue DECIMAL(10, 2) DEFAULT 0,
    cost DECIMAL(10, 2) DEFAULT 0
);

-- 客户行为表
CREATE TABLE customer_behaviors (
    behavior_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    event_type VARCHAR(50) NOT NULL,
    product_id INTEGER REFERENCES products(product_id),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(100),
    page_url VARCHAR(200),
    device_type VARCHAR(50),
    ip_address VARCHAR(50)
);

-- 销售人员表
CREATE TABLE salespeople (
    salesperson_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    termination_date DATE,
    manager_id INTEGER REFERENCES salespeople(salesperson_id),
    commission_rate DECIMAL(5, 2) DEFAULT 0
);

-- 插入测试数据

-- 插入客户数据
INSERT INTO customers (first_name, last_name, email, phone, address, city, country, postal_code, registration_date, last_login_date, is_active)
VALUES
('张', '伟', 'zhang.wei@example.com', '13800138001', '北京路123号', '上海', '中国', '200000', '2022-01-15', '2023-03-20 14:30:00', TRUE),
('李', '娜', 'li.na@example.com', '13800138002', '南京西路456号', '上海', '中国', '200001', '2022-02-20', '2023-03-21 09:15:00', TRUE),
('王', '芳', 'wang.fang@example.com', '13800138003', '朝阳区建国路789号', '北京', '中国', '100000', '2022-03-10', '2023-03-19 16:45:00', TRUE),
('刘', '洋', 'liu.yang@example.com', '13800138004', '天河区体育西路101号', '广州', '中国', '510000', '2022-04-05', '2023-03-18 11:20:00', TRUE),
('陈', '明', 'chen.ming@example.com', '13800138005', '江宁区胜太路202号', '南京', '中国', '210000', '2022-05-12', '2023-03-17 13:40:00', TRUE),
('赵', '霞', 'zhao.xia@example.com', '13800138006', '五道口303号', '北京', '中国', '100000', '2022-06-18', '2023-03-16 10:30:00', TRUE),
('杨', '光', 'yang.guang@example.com', '13800138007', '莲花路404号', '深圳', '中国', '518000', '2022-07-22', '2023-03-15 15:50:00', TRUE),
('周', '婷', 'zhou.ting@example.com', '13800138008', '静安区南京路505号', '上海', '中国', '200002', '2022-08-30', '2023-03-14 08:25:00', TRUE),
('吴', '强', 'wu.qiang@example.com', '13800138009', '洪山区珞瑜路606号', '武汉', '中国', '430000', '2022-09-14', '2023-03-13 17:10:00', TRUE),
('郑', '秀', 'zheng.xiu@example.com', '13800138010', '西湖区文三路707号', '杭州', '中国', '310000', '2022-10-05', '2023-03-12 12:35:00', TRUE);

-- 插入产品类别数据
INSERT INTO product_categories (name, description, parent_category_id)
VALUES
('电子产品', '所有电子设备及配件', NULL),
('手机', '智能手机及配件', 1),
('电脑', '台式机和笔记本电脑', 1),
('服装', '各类服装', NULL),
('男装', '男士服装', 4),
('女装', '女士服装', 4),
('家居', '家居用品', NULL),
('厨房', '厨房用具和电器', 7),
('卧室', '卧室家具和装饰', 7),
('食品', '各类食品和饮料', NULL);

-- 插入产品数据
INSERT INTO products (name, description, category_id, price, cost, stock_quantity, created_at, updated_at, is_active)
VALUES
('iPhone 13', '苹果最新款智能手机', 2, 5999.00, 4200.00, 100, '2023-01-01', '2023-03-01', TRUE),
('华为P50', '华为高端旗舰手机', 2, 4999.00, 3500.00, 80, '2023-01-02', '2023-03-02', TRUE),
('小米12', '小米最新旗舰', 2, 3999.00, 2800.00, 120, '2023-01-03', '2023-03-03', TRUE),
('MacBook Pro', '苹果专业笔记本电脑', 3, 12999.00, 9000.00, 50, '2023-01-04', '2023-03-04', TRUE),
('联想ThinkPad', '商务笔记本电脑', 3, 8999.00, 6000.00, 60, '2023-01-05', '2023-03-05', TRUE),
('戴尔XPS', '高性能笔记本电脑', 3, 9999.00, 7000.00, 45, '2023-01-06', '2023-03-06', TRUE),
('棉质T恤', '舒适透气男士T恤', 5, 129.00, 50.00, 200, '2023-01-07', '2023-03-07', TRUE),
('牛仔裤', '经典款男士牛仔裤', 5, 299.00, 120.00, 150, '2023-01-08', '2023-03-08', TRUE),
('连衣裙', '夏季女士连衣裙', 6, 359.00, 150.00, 180, '2023-01-09', '2023-03-09', TRUE),
('休闲裤', '女士休闲裤', 6, 259.00, 100.00, 160, '2023-01-10', '2023-03-10', TRUE),
('电饭煲', '智能电饭煲', 8, 599.00, 300.00, 80, '2023-01-11', '2023-03-11', TRUE),
('不粘锅', '不粘煎锅', 8, 199.00, 80.00, 100, '2023-01-12', '2023-03-12', TRUE),
('双人床', '1.8米双人实木床', 9, 2999.00, 1500.00, 30, '2023-01-13', '2023-03-13', TRUE),
('床垫', '记忆棉床垫', 9, 1999.00, 800.00, 40, '2023-01-14', '2023-03-14', TRUE),
('巧克力', '比利时进口巧克力', 10, 99.00, 40.00, 300, '2023-01-15', '2023-03-15', TRUE);

-- 插入订单数据
INSERT INTO orders (customer_id, order_date, status, shipping_address, shipping_city, shipping_country, shipping_postal_code, shipping_method, payment_method, total_amount, discount_amount, shipping_amount)
VALUES
(1, '2023-02-01 10:15:00', 'completed', '北京路123号', '上海', '中国', '200000', '快递', '信用卡', 6098.00, 0.00, 99.00),
(2, '2023-02-02 14:30:00', 'completed', '南京西路456号', '上海', '中国', '200001', '快递', '支付宝', 5098.00, 0.00, 99.00),
(3, '2023-02-03 16:45:00', 'completed', '朝阳区建国路789号', '北京', '中国', '100000', '快递', '微信支付', 4098.00, 0.00, 99.00),
(4, '2023-02-04 11:20:00', 'completed', '天河区体育西路101号', '广州', '中国', '510000', '快递', '信用卡', 13098.00, 0.00, 99.00),
(5, '2023-02-05 13:40:00', 'completed', '江宁区胜太路202号', '南京', '中国', '210000', '快递', '支付宝', 9098.00, 0.00, 99.00),
(6, '2023-02-06 10:30:00', 'completed', '五道口303号', '北京', '中国', '100000', '快递', '微信支付', 10098.00, 0.00, 99.00),
(7, '2023-02-07 15:50:00', 'shipped', '莲花路404号', '深圳', '中国', '518000', '快递', '信用卡', 228.00, 0.00, 99.00),
(8, '2023-02-08 08:25:00', 'shipped', '静安区南京路505号', '上海', '中国', '200002', '快递', '支付宝', 398.00, 0.00, 99.00),
(9, '2023-02-09 17:10:00', 'processing', '洪山区珞瑜路606号', '武汉', '中国', '430000', '快递', '微信支付', 458.00, 0.00, 99.00),
(10, '2023-02-10 12:35:00', 'processing', '西湖区文三路707号', '杭州', '中国', '310000', '快递', '信用卡', 358.00, 0.00, 99.00),
(1, '2023-02-15 09:45:00', 'completed', '北京路123号', '上海', '中国', '200000', '快递', '支付宝', 698.00, 0.00, 99.00),
(2, '2023-02-16 13:20:00', 'completed', '南京西路456号', '上海', '中国', '200001', '快递', '微信支付', 298.00, 0.00, 99.00),
(3, '2023-02-17 16:30:00', 'shipped', '朝阳区建国路789号', '北京', '中国', '100000', '快递', '信用卡', 3098.00, 0.00, 99.00),
(4, '2023-02-18 11:10:00', 'shipped', '天河区体育西路101号', '广州', '中国', '510000', '快递', '支付宝', 2098.00, 0.00, 99.00),
(5, '2023-02-19 14:25:00', 'processing', '江宁区胜太路202号', '南京', '中国', '210000', '快递', '微信支付', 198.00, 0.00, 99.00);

-- 插入订单项目数据
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_percent)
VALUES
(1, 1, 1, 5999.00, 0.00),
(2, 2, 1, 4999.00, 0.00),
(3, 3, 1, 3999.00, 0.00),
(4, 4, 1, 12999.00, 0.00),
(5, 5, 1, 8999.00, 0.00),
(6, 6, 1, 9999.00, 0.00),
(7, 7, 1, 129.00, 0.00),
(8, 8, 1, 299.00, 0.00),
(9, 9, 1, 359.00, 0.00),
(10, 10, 1, 259.00, 0.00),
(11, 11, 1, 599.00, 0.00),
(12, 8, 1, 299.00, 0.00),
(13, 13, 1, 2999.00, 0.00),
(14, 14, 1, 1999.00, 0.00),
(15, 15, 1, 99.00, 0.00);

-- 插入库存数据
INSERT INTO inventory (product_id, warehouse_id, quantity, last_updated)
VALUES
(1, 1, 100, '2023-03-01'),
(2, 1, 80, '2023-03-01'),
(3, 1, 120, '2023-03-01'),
(4, 1, 50, '2023-03-01'),
(5, 1, 60, '2023-03-01'),
(6, 1, 45, '2023-03-01'),
(7, 2, 200, '2023-03-01'),
(8, 2, 150, '2023-03-01'),
(9, 2, 180, '2023-03-01'),
(10, 2, 160, '2023-03-01'),
(11, 3, 80, '2023-03-01'),
(12, 3, 100, '2023-03-01'),
(13, 3, 30, '2023-03-01'),
(14, 3, 40, '2023-03-01'),
(15, 4, 300, '2023-03-01');

-- 插入营销活动数据
INSERT INTO marketing_campaigns (name, description, start_date, end_date, budget, status)
VALUES
('春节促销', '春节期间全场8折', '2023-01-15', '2023-01-30', 50000.00, 'completed'),
('38女神节', '女装类商品7折', '2023-03-01', '2023-03-08', 30000.00, 'completed'),
('开学季', '电子产品满减', '2023-02-20', '2023-03-10', 40000.00, 'completed'),
('夏季新品', '夏季新品首发', '2023-04-01', '2023-04-15', 35000.00, 'planned'),
('618大促', '年中大促销', '2023-06-01', '2023-06-18', 100000.00, 'planned');

-- 插入营销活动结果数据
INSERT INTO campaign_results (campaign_id, date, impressions, clicks, conversions, revenue, cost)
VALUES
(1, '2023-01-15', 10000, 1500, 200, 30000.00, 5000.00),
(1, '2023-01-20', 12000, 1800, 250, 37500.00, 5000.00),
(1, '2023-01-25', 15000, 2200, 300, 45000.00, 5000.00),
(1, '2023-01-30', 18000, 2700, 350, 52500.00, 5000.00),
(2, '2023-03-01', 8000, 1200, 150, 22500.00, 3000.00),
(2, '2023-03-03', 9000, 1350, 180, 27000.00, 3000.00),
(2, '2023-03-05', 10000, 1500, 200, 30000.00, 3000.00),
(2, '2023-03-08', 12000, 1800, 240, 36000.00, 3000.00),
(3, '2023-02-20', 9000, 1350, 170, 25500.00, 4000.00),
(3, '2023-02-25', 10000, 1500, 190, 28500.00, 4000.00),
(3, '2023-03-02', 11000, 1650, 210, 31500.00, 4000.00),
(3, '2023-03-07', 12000, 1800, 230, 34500.00, 4000.00),
(3, '2023-03-10', 13000, 1950, 250, 37500.00, 4000.00);

-- 插入客户行为数据
INSERT INTO customer_behaviors (customer_id, event_type, product_id, timestamp, session_id, page_url, device_type, ip_address)
VALUES
(1, 'page_view', 1, '2023-03-01 10:15:00', 'sess123456', '/products/iphone-13', 'mobile', '192.168.1.1'),
(1, 'add_to_cart', 1, '2023-03-01 10:20:00', 'sess123456', '/products/iphone-13', 'mobile', '192.168.1.1'),
(1, 'purchase', 1, '2023-03-01 10:30:00', 'sess123456', '/checkout', 'mobile', '192.168.1.1'),
(2, 'page_view', 2, '2023-03-02 14:30:00', 'sess234567', '/products/huawei-p50', 'desktop', '192.168.1.2'),
(2, 'add_to_cart', 2, '2023-03-02 14:35:00', 'sess234567', '/products/huawei-p50', 'desktop', '192.168.1.2'),
(2, 'purchase', 2, '2023-03-02 14:45:00', 'sess234567', '/checkout', 'desktop', '192.168.1.2'),
(3, 'page_view', 4, '2023-03-03 16:45:00', 'sess345678', '/products/macbook-pro', 'desktop', '192.168.1.3'),
(3, 'add_to_wishlist', 4, '2023-03-03 16:50:00', 'sess345678', '/products/macbook-pro', 'desktop', '192.168.1.3'),
(4, 'page_view', 9, '2023-03-04 11:20:00', 'sess456789', '/products/dress', 'mobile', '192.168.1.4'),
(4, 'add_to_cart', 9, '2023-03-04 11:25:00', 'sess456789', '/products/dress', 'mobile', '192.168.1.4'),
(5, 'page_view', 11, '2023-03-05 13:40:00', 'sess567890', '/products/rice-cooker', 'tablet', '192.168.1.5'),
(5, 'page_view', 12, '2023-03-05 13:45:00', 'sess567890', '/products/pan', 'tablet', '192.168.1.5'),
(5, 'add_to_compare', 11, '2023-03-05 13:50:00', 'sess567890', '/products/rice-cooker', 'tablet', '192.168.1.5'),
(5, 'add_to_compare', 12, '2023-03-05 13:55:00', 'sess567890', '/products/pan', 'tablet', '192.168.1.5'),
(6, 'search', NULL, '2023-03-06 10:30:00', 'sess678901', '/search?q=laptop', 'desktop', '192.168.1.6'),
(6, 'page_view', 6, '2023-03-06 10:35:00', 'sess678901', '/products/dell-xps', 'desktop', '192.168.1.6'),
(7, 'page_view', 13, '2023-03-07 15:50:00', 'sess789012', '/products/bed', 'mobile', '192.168.1.7'),
(8, 'search', NULL, '2023-03-08 08:25:00', 'sess890123', '/search?q=jeans', 'tablet', '192.168.1.8'),
(8, 'page_view', 8, '2023-03-08 08:30:00', 'sess890123', '/products/jeans', 'tablet', '192.168.1.8'),
(9, 'page_view', 14, '2023-03-09 17:10:00', 'sess901234', '/products/mattress', 'desktop', '192.168.1.9'),
(10, 'page_view', 15, '2023-03-10 12:35:00', 'sess012345', '/products/chocolate', 'mobile', '192.168.1.10'),
(10, 'add_to_cart', 15, '2023-03-10 12:40:00', 'sess012345', '/products/chocolate', 'mobile', '192.168.1.10');

-- 插入销售人员数据
INSERT INTO salespeople (first_name, last_name, email, phone, hire_date, termination_date, manager_id, commission_rate)
VALUES
('王', '经理', 'wang.manager@example.com', '13900139001', '2020-01-10', NULL, NULL, 0.10),
('李', '主管', 'li.supervisor@example.com', '13900139002', '2020-03-15', NULL, 1, 0.08),
('张', '销售', 'zhang.sales@example.com', '13900139003', '2021-05-20', NULL, 2, 0.05),
('刘', '销售', 'liu.sales@example.com', '13900139004', '2021-07-10', NULL, 2, 0.05),
('陈', '销售', 'chen.sales@example.com', '13900139005', '2022-01-15', NULL, 2, 0.05),
('赵', '销售', 'zhao.sales@example.com', '13900139006', '2022-03-20', NULL, 2, 0.05),
('杨', '销售', 'yang.sales@example.com', '13900139007', '2022-06-10', NULL, 2, 0.05); 