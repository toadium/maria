import pydantic
from openai.types.chat.chat_completion_message import ChatCompletionMessage
from openai.types.completion_usage import CompletionUsage
from openai.types.chat.chat_completion_message_tool_call import (
    ChatCompletionMessageToolCall,
)
from typing import Union, Literal, Any, Annotated, Dict


class ToolAddedParams(pydantic.BaseModel):
    tool: Dict[str, Any]


class ToolAdded(pydantic.BaseModel):
    method: Literal["maria.agent.tool_added"]
    params: ToolAddedParams


class UserMessageParams(pydantic.BaseModel):
    message: Dict[str, Any]


class UserMessage(pydantic.BaseModel):
    method: Literal["maria.agent.message"]
    params: UserMessageParams


class ConversationStart(pydantic.BaseModel):
    method: Literal["maria.agent.conversation_start"]
    params: Dict[str, Any] = pydantic.Field(default_factory=dict)


class ConversationEnd(pydantic.BaseModel):
    method: Literal["maria.agent.conversation_end"]
    params: Dict[str, Any] = pydantic.Field(default_factory=dict)


class RequestCompletedParams(pydantic.BaseModel):
    usage: CompletionUsage
    message: ChatCompletionMessage


class RequestCompleted(pydantic.BaseModel):
    method: Literal["maria.agent.request_completed"]
    params: RequestCompletedParams


class PostToolCallParams(pydantic.BaseModel):
    tool_call: ChatCompletionMessageToolCall
    value: Any = pydantic.Field(alias='json')
    text: str


class PostToolCall(pydantic.BaseModel):
    method: Literal["maria.agent.post_tool_call"]
    params: PostToolCallParams


Notification = Annotated[
    Union[
        ToolAdded,
        UserMessage,
        ConversationStart,
        ConversationEnd,
        RequestCompleted,
        PostToolCall,
    ],
    pydantic.Field(discriminator="method"),
]

notification = pydantic.TypeAdapter(Notification)
