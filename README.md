# Database API Service

一个用于业务分析的数据库API服务。

## 环境设置

1. 克隆此仓库
2. 安装依赖: `pip install -r requirements.txt`
3. 创建`.env`文件在项目根目录，设置以下环境变量:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=business_analytics
DB_USER=postgres
DB_PASSWORD=你的密码
```

**注意**: 确保不要将你的实际数据库密码提交到Git仓库中！

## 运行服务

```
python app.py
``` 