from flask import Flask, request, jsonify
from functools import wraps
from dotenv import load_dotenv
import logging
import sys

from tool_use_gemini import get_response
from gmail_tool import get_creds

load_dotenv()

app = Flask(__name__)

def set_up_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        stream=sys.stdout
    )

set_up_logging()

def handle_exceptions(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    return wrapper


def required_keys(*required_keys):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            data = request.get_json()
            if not data:
                return jsonify({'error': 'No JSON data provided'}), 400
            
            missing_keys = [key for key in required_keys if key not in data]
            if missing_keys:
                return jsonify({
                    'error': f'Missing required fields: {", ".join(missing_keys)}'
                }), 400
                
            return f(*args, **kwargs)
        return wrapper
    return decorator

def require_auth(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Missing Authorization header'}), 401
            
        # Remove 'Bearer ' prefix if present
        token = token.replace('Bearer ', '')
        # Add token to kwargs so the route can access it
        kwargs['token'] = token
        return f(*args, **kwargs)
    return wrapper


@app.route('/')
def index():
    return 'Hello, World!'


# used only for local testing
@app.route('/token', methods=['GET'])
@handle_exceptions
def token():
    creds = get_creds()
    return jsonify({'token': creds.token})


@app.route('/chat', methods=['POST'])
@required_keys('messages')
@require_auth
@handle_exceptions
def chat(token: str):
    data = request.get_json()
    messages = data['messages']

    response = get_response(messages, token)
    return jsonify({'response': response})

if __name__ == '__main__':
    # only run on local
    app.run(port=1234, debug=True)