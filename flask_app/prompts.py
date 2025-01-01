SYSTEM_MESSAGE = """
You are a smart email assistant. You have been provided with access to the user's inbox.
You can search for emails, summarise one or more emails, generate a response to any email.
While summarising emails, begin the answer with an overall summary of the emails and then move on to individual summaries by clubbing related emails if needed.
Do not mention any search query in the answer.
"""

# Fix timestamp issue
TOOL_DESCRIPTION = """
Search for emails from the user's inbox given a search operator.
The search operator can include the following:
- Sender/Recipient of the email
    - from/to:<email_address> - For example, from:me or to:david@example.com or from:*@example.com
    - cc/bcc:<email_address> - For example, cc:john@example.com or bcc:jane@example.com
    - list:<mailing_list_address> - Check mails from a mailing list.For example, list:info@example.com
- Content of the email
    - subject:<word> - Find emails by a word in the subject line. For example, subject:dinner.
    - <word> AROUND <number> <word> - Find emails with words near each other. Use the number to say how many words apart the words can be. Add quotes to find messages in which the word you put first stays first.
    For example: holiday AROUND 10 vacation or "secret AROUND 25 birthday"
    - "<word/phrase>": Search for emails with an exact word or phrase. For example: "dinner and movie tonight"
- Date of the email
    - after/before:<date> - For example, after:2024/01/01 or before:2024/01/01
    - older_than/newer_than:<number> - Search for emails older or newer than a time period. Use d (day), m (month), or y (year). For example, older_than:1y or newer_than:2d
- Email Properties
    - category:<category_name> - Find emails under one of your categories. For example, category:social/forums/promotions/updates/etc.
    - has:<property> - Find emails that include attachments (has:attachment), inline images (has:image), youtube videos (has;youtube), drive files (has:drive), google docs (has:document), 
    google sheet (has:spreadsheet) or google slides (has:presentation).
    - filename:<filename> - Find emails with attachments that match the filename or filetype. For example, filename:report.pdf or filename:pdf
    - is:<status> - Find emails according to their status. For example, is:important/starred/unread/read/muted.
    - in:<location> - Find emails in specific locations. For example, in:trash, in: anywhere (to include spam and trash emails) or in:snoozed (for snoozed emails).
    - size/larger/smaller:<number> - Find emails larger or smaller or equal to a specific size. For example, size:100000 or larger:100k or smaller:10M
You can also combine one or more of these criteria. By default, the search operators separated by space will be combined using AND. You can also use the following syntax to combine the search operators:
- OR: Combine multiple search criteria to find emails that match at least one of them. For example, from:me OR subject:dinner
- "-": Exclude emails that match a specific search criteria. For example, -from:me
- ( ) : Group multiple search criteria. For example, (from:me subject:dinner) OR subject:movie. Another example, subject:(dinner movie). This will search for emails with the word "dinner" AND "movie" in the subject.

Specific Instructions:
- Do not limit search results unless the user specifically asks for it.
- If the user asks for emails in the primary inbox then search for category:primary.
- If the user has read the email then search for is:read.
- When asked to search for emails that talk about certain topics, then search for the topic in the body of the email and not only in the subject.
- When asked to search everywhere/ or to include spam and trash emails then use in:anywhere to include spam and trash emails.
- Use has:image to return emails that contain images in the email body.
- Use filename:(jpg OR jpeg OR png) to return emails that have images in the attachments.

Here are a few examples of how to use the search operator:

Question: Summarise all mails from paytm to me. 
search_operator = from:*@paytm.com to:me

Question: Find all emails containing attachments received in the last 3 days.
search_operator = has:attachment newer_than:3d

Question: Find all emails that talk about memories, events or birthdays. But not about John.
search_operator = (memories OR events OR birthdays) -john
"""

FUNCTION_DECLARATION = {
    'function_declarations': [{
        'name': 'search_emails',
        'description': TOOL_DESCRIPTION,
        'parameters': {
            'type_': 'OBJECT',
            'properties': {
                'search_operator': {
                    'type_': 'STRING',
                    'description': 'The search operator to use'
                },
                'num_search_results': {
                    'type_': 'INTEGER',
                    'description': 'The number of search results to return. Minimum value is 3.'
                }
            },
            'required': ['search_operator']
        }
    }]
}