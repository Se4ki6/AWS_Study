import json
import boto3
import os
from decimal import Decimal

# DynamoDBリソースの初期化（ハンドラーの外に書くことで、再実行時に速くなる！）
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

# DynamoDBの数値型(Decimal)をJSONに変換するためのヘルパー
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            # 整数ならint、小数ならfloatに変換
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    # API Gatewayから届くメソッドとパスを取得
    # HTTP API (Payload 2.0) の形式に合わせて抽出
    method = event.get('requestContext', {}).get('http', {}).get('method')
    # パスを取得（例: /snack_war）
    raw_path = event.get('rawPath', '/')
    poll_id = raw_path.strip('/') # スラッシュを除去して pollId にする

    try:
        # --- 1. 投票結果の取得 (GET) ---
        if method == 'GET':
            # pollIdをパーティションキーにして全件取得（Query）
            response = table.query(
                KeyConditionExpression=boto3.dynamodb.conditions.Key('pollId').eq(poll_id)
            )
            items = response.get('Items', [])
            
            return {
                'statusCode': 200,
                'body': json.dumps({'pollId': poll_id, 'results': items}, cls=DecimalEncoder)
            }

        # --- 2. 投票の実行 (POST) ---
        elif method == 'POST':
            # フロントエンドから送られてきたボディ（JSON）を解析
            body = json.loads(event.get('body', '{}'))
            option_id = body.get('optionId')
            
            if not option_id:
                return {'statusCode': 400, 'body': json.dumps('optionId is required')}

            # アトミックカウンタで「votes」属性を+1する
            response = table.update_item(
                Key={
                    'pollId': poll_id,
                    'optionId': option_id
                },
                UpdateExpression="ADD votes :inc",
                ExpressionAttributeValues={':inc': 1},
                ReturnValues="UPDATED_NEW"
            )

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': '投票完了！',
                    'updatedVotes': response['Attributes']['votes']
                }, cls=DecimalEncoder)
            }

        # GET/POST 以外
        return {
            'statusCode': 405,
            'body': json.dumps('Method Not Allowed')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'サーバーでエラーが発生しました'})
        }