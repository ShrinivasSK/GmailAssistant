import os.path
import requests
import re
import base64
from dataclasses import dataclass
from email_reply_parser import EmailReplyParser
from bs4 import BeautifulSoup
from dotenv import load_dotenv
import logging

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.errors import HttpError

load_dotenv()

SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]
CLIENT_SECRET_FILE = "./client_secret_local.json"

# used only for local testing
def get_creds():
    creds = None
    if os.path.exists("token.json"):
        creds = Credentials.from_authorized_user_file("token.json", SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                CLIENT_SECRET_FILE, SCOPES
            )
            creds = flow.run_local_server(port=56521, prompt='consent', access_type='offline')
        with open("token.json", "w") as token:
            token.write(creds.to_json())
    return creds


@dataclass
class Email:
    message_id: str
    from_email: str
    subject: str
    date: str
    body: str
    attachments: list[str]

    def __str__(self):
        return f"<From>{self.from_email}</From>\n<Subject>{self.subject}</Subject>\n<Date>{self.date}</Date>\n<Body>{self.body}</Body>\n{'<Attachments>' + ', '.join(self.attachments) + '</Attachments>' if len(self.attachments) > 0 else ''}"

    def to_dict(self):
        return {
            'message_id': self.message_id,
            'from_email': self.from_email,
            'subject': self.subject,
            'date': self.date,
        }

def extract_text_from_html(html_data):
    if not html_data:
        return ''
    soup = BeautifulSoup(html_data, 'html.parser')
    return soup.get_text()


def clean_message_body(body: str) -> str:
    body = EmailReplyParser.parse_reply(body)  # ignores older replies in threads
    body = re.sub(r'https?://\S+|www\.\S+', '', body)
    cleaned_lines = [line.strip() for line in body.splitlines() if line.strip()]
    return "\n".join(cleaned_lines)


def get_message_details(message_id: str, token: str, parts: list[str] = ['from', 'subject', 'date', 'body', 'attachments']) -> Email:
    try:
        MSG_URL = f'https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}'
        headers = {
            'Authorization': f'Bearer {token}',
            'Accept': 'application/json',
        }
        response = requests.get(MSG_URL, headers=headers, params={"format": "full"})
        response.raise_for_status()
        message = response.json()
        response_headers = message['payload']['headers']
        email_from = next((header['value'] for header in response_headers if header['name'] == 'From'), None)
        email_subject = next((header['value'] for header in response_headers if header['name'] == 'Subject'), None)
        email_date = next((header['value'] for header in response_headers if header['name'] == 'Date'), None)
        attachments = []
        text_body = ''
        html_body = ''
        if 'parts' in message['payload']:
            for part in message['payload']['parts']:
                if filename := part.get('filename'):
                    attachments.append(filename)
                elif part['mimeType'] == 'text/plain':
                    text_body = base64.urlsafe_b64decode(part['body']['data']).decode('utf-8')
                elif part['mimeType'] == 'text/html':
                    html_body = base64.urlsafe_b64decode(part['body']['data']).decode('utf-8')
        else:
            mimeType = message['payload']['mimeType']
            if mimeType == 'text/html':
                html_body = base64.urlsafe_b64decode(message['payload']['body']['data']).decode('utf-8')
            elif mimeType == 'text/plain':
                text_body = base64.urlsafe_b64decode(message['payload']['body']['data']).decode('utf-8')
        body = text_body if text_body else extract_text_from_html(html_body)
        cleaned_text = clean_message_body(body)
        return Email(message_id=message_id, from_email=email_from, subject=email_subject, date=email_date, body=cleaned_text.strip(), attachments=attachments)
    except Exception as e:
        logging.error(f"Error getting message details for {message_id} {e}")
        return None


def get_email_messages(token: str, query: str, num_search_results: int = 10) -> list[Email]:
    try:
        email_responses = []
        MSG_LIST_URL = "https://gmail.googleapis.com/gmail/v1/users/me/messages"
        headers = {
            'Authorization': f'Bearer {token}',
            'Accept': 'application/json',
        }
        params = {
            'q': query,
        }
        response = requests.get(MSG_LIST_URL, headers=headers, params=params)
        response.raise_for_status()
        emails = response.json().get("messages", [])
        logging.info(f'Found {len(emails)} emails')
        for email in emails[:num_search_results]:
            email_details = get_message_details(email["id"], token)
            logging.debug(f'Email details {email["id"]}: {email_details}')
            if email_details:
                email_responses.append(email_details)
        if email_responses:
            return '\n'.join([str(email) for email in email_responses]), [email.to_dict() for email in email_responses]
        return 'No emails found.', []
    except HttpError as e:
        logging.error(f'Error fetching emails: {e}')
        return f'Some error occurred in fetching emails: {e}. Please try again.', []


if __name__ == "__main__":
    creds = get_creds()
    messages = get_email_messages(creds.token, 'from:no-reply@paytmbank.com')
    print(messages)