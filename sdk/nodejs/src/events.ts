import type {
  ChatCompletionMessage,
  ChatCompletionMessageToolCall,
} from "openai/resources/chat/completions";
import type { CompletionUsage } from "openai/resources";

export interface ToolAddedParams {
  tool: Record<string, unknown>;
}

export interface ToolAdded {
  method: "maria.agent.tool_added";
  params: ToolAddedParams;
}

export interface UserMessageParams {
  message: { role: "user"; content: unknown };
}

export interface UserMessage {
  method: "maria.agent.message";
  params: UserMessageParams;
}

export interface ConversationStart {
  method: "maria.agent.conversation_start";
  params: Record<string, never>;
}

export interface ConversationEnd {
  method: "maria.agent.conversation_end";
  params: Record<string, never>;
}

export interface RequestCompletedParams {
  usage: CompletionUsage;
  message: ChatCompletionMessage;
}

export interface RequestCompleted {
  method: "maria.agent.request_completed";
  params: RequestCompletedParams;
}

export interface PostToolCallParams {
  tool_call: ChatCompletionMessageToolCall;
  json: any;
  text: string;
}

export interface PostToolCall {
  method: "maria.agent.post_tool_call";
  params: PostToolCallParams;
}

export type Notification =
  | ToolAdded
  | UserMessage
  | ConversationStart
  | ConversationEnd
  | RequestCompleted
  | PostToolCall;
