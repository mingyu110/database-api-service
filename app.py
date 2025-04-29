from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import json
import pandas as pd
import matplotlib.pyplot as plt
import io
import base64
from datetime import datetime, date
import os
from dotenv import load_dotenv
import decimal
from psycopg2.extensions import register_adapter, AsIs
import numpy as np
import matplotlib
matplotlib.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS', 'sans-serif']  
matplotlib.rcParams['axes.unicode_minus'] = False  # 正确显示负号

load_dotenv()

app = Flask(__name__)
CORS(app)

# 添加Decimal到float的适配器
def adapt_decimal(decimal_value):
    return AsIs(float(decimal_value))

register_adapter(decimal.Decimal, adapt_decimal)

# 自定义JSON编码器处理Decimal类型
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        return super(CustomJSONEncoder, self).default(obj)

# 配置Flask使用自定义编码器
app.json_encoder = CustomJSONEncoder

# 自定义JSON编码器处理所有特殊类型
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return float(o)
        elif isinstance(o, np.integer):
            return int(o)
        elif isinstance(o, np.floating):
            return float(o)
        elif isinstance(o, np.ndarray):
            return o.tolist()
        elif isinstance(o, (date, datetime)):
            return o.isoformat()
        else:
            return super(DecimalEncoder, self).default(o)

# 数据库配置
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'port': int(os.environ.get('DB_PORT', 5432)),
    'database': os.environ.get('DB_NAME', 'business_analytics'),
    'user': os.environ.get('DB_USER', 'postgres'),
    'password': os.environ.get('DB_PASSWORD', 'your_password')
}

# 在所有需要的地方修改
DEC2FLOAT = psycopg2.extensions.new_type(
    psycopg2.extensions.DECIMAL.values,
    'DEC2FLOAT',
    lambda value, curs: float(value) if value is not None else None)
psycopg2.extensions.register_type(DEC2FLOAT)

# 1. 数据库查询API
@app.route('/query', methods=['POST'])
def execute_query():
    data = request.json
    if not data or 'sql' not in data:
        return jsonify({"error": "未提供SQL查询"}), 400
        
    sql = data['sql']
    output_format = data.get('output_format', 'json')  # 默认为json格式
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(sql)
        results = cur.fetchall()
        
        # 检查是否为DML操作(INSERT, UPDATE, DELETE)
        if cur.rowcount >= 0 and not results:
            return jsonify({"message": f"操作成功，影响了{cur.rowcount}行"})
            
        cur.close()
        conn.close()
        
        # 根据要求的输出格式返回结果
        if output_format == 'json':
            return jsonify({"results": results})
        elif output_format == 'csv':
            df = pd.DataFrame(results)
            csv_data = df.to_csv(index=False)
            return Response(
                csv_data,
                mimetype="text/csv",
                headers={"Content-disposition": f"attachment; filename=query_result_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"}
            )
        elif output_format == 'chart':
            # 确保结果适合生成图表
            if not results:
                return jsonify({"error": "没有数据可以生成图表"}), 400
                
            df = pd.DataFrame(results)
            
            # 不再使用matplotlib，直接返回数据
            chart_type = data.get('chart_type', 'bar')
            
            # 准备数据
            if len(df.columns) >= 2:
                labels = [str(x) for x in df.iloc[:, 0]]
                values = df.iloc[:, 1].tolist()
                
                # 转换Decimal类型
                values = [float(v) if isinstance(v, decimal.Decimal) else v for v in values]
                
                chart_data = {
                    "type": chart_type,
                    "labels": labels,
                    "values": values,
                    "columns": list(df.columns),
                    "data": df.to_dict(orient='records'),
                    "title": data.get('title', '数据可视化')
                }
                
                return jsonify({"chart_data": chart_data})
            else:
                return jsonify({"error": "图表需要至少两列数据"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# 2. 数据库结构API
@app.route('/schema', methods=['GET'])
def get_schema():
    table_name = request.args.get('table_name')
    include_sample = request.args.get('include_sample', 'false').lower() == 'true'
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        if table_name:
            # 获取特定表结构
            cur.execute("""
                SELECT column_name as name, data_type as type, 
                       (is_nullable = 'YES') as nullable,
                       column_default as default_value
                FROM information_schema.columns
                WHERE table_name = %s AND table_schema = 'public'
                ORDER BY ordinal_position
            """, (table_name,))
            columns = cur.fetchall()
            
            # 获取主键信息
            cur.execute("""
                SELECT a.attname
                FROM   pg_index i
                JOIN   pg_attribute a ON a.attrelid = i.indrelid
                                      AND a.attnum = ANY(i.indkey)
                WHERE  i.indrelid = %s::regclass
                AND    i.indisprimary
            """, (table_name,))
            primary_keys = [row['attname'] for row in cur.fetchall()]
            
            # 获取外键信息
            cur.execute("""
                SELECT
                    kcu.column_name as column_name,
                    ccu.table_name as foreign_table,
                    ccu.column_name as foreign_column
                FROM 
                    information_schema.table_constraints AS tc 
                    JOIN information_schema.key_column_usage AS kcu
                      ON tc.constraint_name = kcu.constraint_name
                      AND tc.table_schema = kcu.table_schema
                    JOIN information_schema.constraint_column_usage AS ccu
                      ON ccu.constraint_name = tc.constraint_name
                      AND ccu.table_schema = tc.table_schema
                WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = %s
            """, (table_name,))
            foreign_keys = cur.fetchall()
            
            # 获取样本数据
            sample_data = []
            if include_sample:
                try:
                    cur.execute(f"SELECT * FROM {table_name} LIMIT 5")
                    sample_data = cur.fetchall()
                except:
                    # 忽略样本数据获取错误
                    pass
            
            tables = [{
                "name": table_name,
                "columns": columns,
                "primary_keys": primary_keys,
                "foreign_keys": foreign_keys,
                "sample_data": sample_data
            }]
        else:
            # 获取所有表结构
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
            """)
            table_names = [row['table_name'] for row in cur.fetchall()]
            
            tables = []
            for table in table_names:
                cur.execute("""
                    SELECT column_name as name, data_type as type, 
                           (is_nullable = 'YES') as nullable,
                           column_default as default_value
                    FROM information_schema.columns
                    WHERE table_name = %s AND table_schema = 'public'
                    ORDER BY ordinal_position
                """, (table,))
                columns = cur.fetchall()
                
                # 获取主键信息
                cur.execute("""
                    SELECT a.attname
                    FROM   pg_index i
                    JOIN   pg_attribute a ON a.attrelid = i.indrelid
                                          AND a.attnum = ANY(i.indkey)
                    WHERE  i.indrelid = %s::regclass
                    AND    i.indisprimary
                """, (table,))
                primary_keys = [row['attname'] for row in cur.fetchall()]
                
                # 获取外键信息
                cur.execute("""
                    SELECT
                        kcu.column_name as column_name,
                        ccu.table_name as foreign_table,
                        ccu.column_name as foreign_column
                    FROM 
                        information_schema.table_constraints AS tc 
                        JOIN information_schema.key_column_usage AS kcu
                          ON tc.constraint_name = kcu.constraint_name
                          AND tc.table_schema = kcu.table_schema
                        JOIN information_schema.constraint_column_usage AS ccu
                          ON ccu.constraint_name = tc.constraint_name
                          AND ccu.table_schema = tc.table_schema
                    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = %s
                """, (table,))
                foreign_keys = cur.fetchall()
                
                # 获取表行数估计
                cur.execute("""
                    SELECT n_live_tup::integer as row_count
                    FROM pg_stat_user_tables
                    WHERE relname = %s
                """, (table,))
                row_count = cur.fetchone()
                
                table_info = {
                    "name": table,
                    "columns": columns,
                    "primary_keys": primary_keys,
                    "foreign_keys": foreign_keys,
                    "row_count": row_count['row_count'] if row_count else None
                }
                
                # 获取样本数据
                if include_sample:
                    try:
                        cur.execute(f"SELECT * FROM {table} LIMIT 5")
                        table_info["sample_data"] = cur.fetchall()
                    except:
                        table_info["sample_data"] = []
                
                tables.append(table_info)
        
        cur.close()
        conn.close()
        
        return jsonify({"tables": tables})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# 3. 数据分析API
@app.route('/analyze', methods=['POST'])
def analyze_data():
    data = request.json
    if not data or 'sql' not in data:
        return jsonify({"error": "未提供SQL查询"}), 400
        
    sql = data['sql']
    analysis_type = data.get('analysis_type', 'summary')
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(sql)
        results = cur.fetchall()
        
        if not results:
            return jsonify({"error": "没有数据可以分析"}), 400
            
        df = pd.DataFrame(results)
        
        # 在返回结果前增加以下函数和处理代码
        def convert_decimal(obj):
            if isinstance(obj, dict):
                return {str(k) if isinstance(k, (date, datetime)) else k: convert_decimal(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_decimal(i) for i in obj]
            elif isinstance(obj, decimal.Decimal):
                return float(obj)
            elif isinstance(obj, (date, datetime)):
                return obj.isoformat()
            else:
                return obj
        
        if analysis_type == 'summary':
            # 基本统计摘要
            summary = {}
            for col in df.select_dtypes(include=['int64', 'float64']).columns:
                summary[col] = {
                    "min": df[col].min(),
                    "max": df[col].max(),
                    "mean": df[col].mean(),
                    "median": df[col].median(),
                    "std": df[col].std()
                }
                
            for col in df.select_dtypes(include=['object']).columns:
                summary[col] = {
                    "unique_values": df[col].nunique(),
                    "most_common": df[col].value_counts().head(3).to_dict()
                }
                
            # 返回前转换
            summary = convert_decimal(summary)
            
            # 替换返回方式
            return Response(
                json.dumps({"analysis": summary}, cls=DecimalEncoder),
                mimetype='application/json'
            )
            
        elif analysis_type == 'correlation':
            # 计算相关性矩阵
            corr_matrix = df.select_dtypes(include=['int64', 'float64']).corr().to_dict()
            # 返回前转换
            corr_matrix = convert_decimal(corr_matrix)
            
            # 替换返回方式
            return Response(
                json.dumps({"analysis": corr_matrix}, cls=DecimalEncoder),
                mimetype='application/json'
            )
            
        elif analysis_type == 'aggregation':
            # 分组聚合分析
            group_col = data.get('group_by')
            agg_col = data.get('aggregate_column')
            agg_func = data.get('aggregate_function', 'sum')
            
            # 转换聚合函数名称
            if agg_func == 'avg':
                agg_func = 'mean'
            
            if not group_col or not agg_col:
                return jsonify({"error": "分组分析需要指定group_by和aggregate_column参数"}), 400
                
            result = df.groupby(group_col)[agg_col].agg(agg_func).to_dict()
            # 返回前转换
            result = convert_decimal(result)
            
            # 替换返回方式
            return Response(
                json.dumps({"analysis": result}, cls=DecimalEncoder),
                mimetype='application/json'
            )
            
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3001)