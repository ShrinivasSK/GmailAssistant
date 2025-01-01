import os
from dotenv import load_dotenv
import google.generativeai as genai
from google.generativeai.protos import Content, Part, FunctionCall, FunctionResponse
import logging

from prompts import FUNCTION_DECLARATION, SYSTEM_MESSAGE
from gmail_tool import get_email_messages

load_dotenv()

def initialise_model():
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    search_emails_tool = genai.protos.Tool(FUNCTION_DECLARATION)
    model = genai.GenerativeModel("gemini-1.5-flash", tools=[search_emails_tool], system_instruction=SYSTEM_MESSAGE)
    return model


def parse_messages_to_contents(messages: list[dict]) -> list[Content]:
    contents = []
    for message in messages:
        if message['role'] == 'user':
            contents.append(Content(role= 'user', parts=[Part(text=message['content'])]))
        elif message['role'] == 'model':
            contents.append(Content(role= 'model', parts=[Part(text=message['content'])]))
        elif message['role'] == 'functionUse':
            if contents[-1].role == 'model':
                contents[-1].parts.append(Part(function_call=FunctionCall(name=message['content']['name'], args=message['content']['args'])))
            else:
                contents.append(Content(role='model', parts=[Part(function_call=FunctionCall(name=message['content']['name'], args=message['content']['args']))]))
        elif message['role'] == 'functionResponse':
            if contents[-1].role == 'user':
                contents[-1].parts.append(Part(function_response=FunctionResponse(name=message['content']['name'], response={'result': message['content']['result']})))
            else:
                contents.append(Content(role='user', parts=[Part(function_response=FunctionResponse(name=message['content']['name'], response={'result': message['content']['result']}))]))
    return contents


def add_function_response(contents: list[Content], messages: list[dict], tool_name: str, result: str):
    contents.append(Content(role='user', parts=[Part(function_response=FunctionResponse(name=tool_name, response={'result': result}))]))
    messages.append({'role': 'functionResponse', 'content': {'name': tool_name, 'result': result}})
    return contents, messages

def add_function_call(contents: list[Content], messages: list[dict], tool_name: str, args: dict):
    contents.append(Content(role='model', parts=[Part(function_call=FunctionCall(name=tool_name, args=args))]))
    messages.append({'role': 'functionCall', 'content': {'name': tool_name, 'args': args}})
    return contents, messages

def add_final_response(contents: list[Content], messages: list[dict], response: str):
    contents.append(Content(role='model', parts=[Part(text=response)]))
    messages.append({'role': 'model', 'content': response})
    return contents, messages

def get_tool_response(tool_name: str, args: dict, token: str) -> FunctionResponse:
    if tool_name == "search_emails":
        if 'search_operator' in args:
            return get_email_messages(token, args['search_operator'], max(min(25, int(args.get('num_search_results', 10))), 3))
        else:
            return 'Please provide a search operator.', []
    else:
        return 'Tool not found.', []


def get_function_call(response):
    for part in response.parts:
        if fn := part.function_call:
            args = {k:v for k, v in fn.args.items()}
            return fn.name, args
    return None


def get_response(messages: list[dict], token: str) -> str:
    model = initialise_model()
    logging.info(f'User message: {messages[-1]["content"]}')
    contents = parse_messages_to_contents(messages)
    relevant_emails = []
    response_messages = []
    while True:
        try:
            resp = model.generate_content(contents)
        except Exception as e:
            logging.error(f"Error generating content: {e} for {contents}: {messages}")
            raise e
        if function_call := get_function_call(resp):
            logging.info(f'Function call: name={function_call[0]}, args={function_call[1]}')
            tool_response, emails = get_tool_response(function_call[0], function_call[1], token)
            logging.info(f'Tool response: {tool_response}')
            contents, response_messages = add_function_call(contents, response_messages, function_call[0], function_call[1])
            contents, response_messages = add_function_response(contents, response_messages, function_call[0], tool_response)
            relevant_emails.extend(emails)
        else:
            logging.info(f'Final response: {resp.text}')
            contents, response_messages = add_final_response(contents, response_messages, resp.text)
            return response_messages, relevant_emails

