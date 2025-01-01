import os
from dotenv import load_dotenv
import google.generativeai as genai
from google.generativeai.protos import Content, Part, FunctionCall, FunctionResponse

from prompts import FUNCTION_DECLARATION, SYSTEM_MESSAGE
from gmail_tool import get_email_messages

load_dotenv()

def initialise_model():
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    search_emails_tool = genai.protos.Tool(FUNCTION_DECLARATION)
    model = genai.GenerativeModel("gemini-1.5-flash", tools=[search_emails_tool], system_instruction=SYSTEM_MESSAGE)
    return model


def parse_messages(messages: list[dict]) -> list[Content]:
    contents = []
    for message in messages:
        if message['role'] == 'user':
            contents.append(Content(role= 'user', parts=[Part(text=message['content'])]))
        elif message['role'] == 'model':
            contents.append(Content(role= 'model', parts=[Part(text=message['content'])]))
        elif message['role'] == 'tool_use':
            if contents[-1].role == 'model':
                contents[-1].parts.append(Part(function_call=FunctionCall(name=message['content']['name'], args=message['content']['args'])))
            else:
                contents.append(Content(role='model', parts=[Part(function_call=FunctionCall(name=message['content']['name'], args=message['content']['args']))]))
        elif message['role'] == 'tool_response':
            if contents[-1].role == 'user':
                contents[-1].parts.append(Part(function_response=FunctionResponse(name=message['content']['name'], result=message['content']['result'])))
            else:
                contents.append(Content(role='user', parts=[Part(function_response=FunctionResponse(name=message['content']['name'], result=message['content']['result']))]))
    return contents


def get_tool_response(tool_name: str, args: dict, token: str) -> FunctionResponse:
    if tool_name == "search_emails":
        if 'search_operator' in args:
            return get_email_messages(token, args['search_operator'], max(min(25, args.get('num_search_results', 10)), 3))
        else:
            return 'Please provide a search operator.'
    else:
        return 'Tool not found.'


def get_function_call(response):
    for part in response.parts:
        if fn := part.function_call:
            args = {k:v for k, v in fn.args.items()}
            return fn.name, args
    return None


def get_response(messages: list[dict], token: str) -> str:
    model = initialise_model()
    contents = parse_messages(messages)
    while True:
        try:
            resp = model.generate_content(contents)
        except Exception as e:
            print(f"Error generating content: {e} for {contents}: {messages}")
            raise e
        if function_call := get_function_call(resp):
            tool_response = get_tool_response(function_call[0], function_call[1], token)
            contents.append(Content(role='model', parts=[Part(function_call=FunctionCall(name=function_call[0], args=function_call[1]))]))
            contents.append(Content(role='user', parts=[Part(function_response=FunctionResponse(name=function_call[0], response={'result': tool_response}))]))
        else:
            return resp.text

