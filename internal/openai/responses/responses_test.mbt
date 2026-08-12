///|
test "responses/ContentType to_json" {
  json_inspect(ContentType::InputText.to_json(), content="\"input_text\"")
  json_inspect(ContentType::OutputText.to_json(), content="\"output_text\"")
  json_inspect(ContentType::Text.to_json(), content="\"text\"")
}

///|
test "responses/ContentType from_json valid" {
  let ct1 : ContentType = @json.from_json("input_text")
  debug_inspect(ct1, content="InputText")
  let ct2 : ContentType = @json.from_json("output_text")
  debug_inspect(ct2, content="OutputText")
  let ct3 : ContentType = @json.from_json("text")
  debug_inspect(ct3, content="Text")
}

///|
test "responses/ContentType from_json invalid" {
  try {
    let _ : ContentType = @json.from_json("invalid")
    fail("expected error")
  } catch {
    _ => ()
  }
}

///|
test "responses/ContentPart to_json" {
  let part = ContentPart::new(type_=ContentType::InputText, text="hello")
  json_inspect(
    part.to_json(),
    content="{\"type\":\"input_text\",\"text\":\"hello\"}",
  )
}

///|
test "responses/ContentPart from_json" {
  let json : Json = { "type": "output_text", "text": "world" }
  let part : ContentPart = @json.from_json(json)
  debug_inspect(part.type_, content="OutputText")
  inspect(part.text, content="\"world\"")
}

///|
test "responses/ContentPart from_json missing type" {
  let json : Json = { "text": "hello" }
  try {
    let _ : ContentPart = @json.from_json(json)
    fail("expected error")
  } catch {
    _ => ()
  }
}

///|
test "responses/ResponseInputItem Message to_json" {
  let item = ResponseInputItem::Message(role="user", content=[
    ContentPart::new(type_=ContentType::InputText, text="hi"),
  ])
  json_inspect(
    item.to_json(),
    content="{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"hi\"}]}",
  )
}

///|
test "responses/ResponseInputItem FunctionCall to_json" {
  let item = ResponseInputItem::FunctionCall(
    call_id="c1",
    name="get_weather",
    arguments="{}",
  )
  json_inspect(
    item.to_json(),
    content="{\"type\":\"function_call\",\"call_id\":\"c1\",\"name\":\"get_weather\",\"arguments\":\"{}\"}",
  )
}

///|
test "responses/ResponseInputItem FunctionCallOutput to_json" {
  let item = ResponseInputItem::FunctionCallOutput(call_id="c1", output="sunny")
  json_inspect(
    item.to_json(),
    content="{\"type\":\"function_call_output\",\"call_id\":\"c1\",\"output\":\"sunny\"}",
  )
}

///|
test "responses/ResponseItem from_json message" {
  let json : Json = {
    "type": "message",
    "role": "assistant",
    "content": [{ "type": "output_text", "text": "Hello!" }],
  }
  let item : ResponseItem = @json.from_json(json)
  guard item is ResponseItem::Message(role~, content~) else {
    fail("expected Message")
  }
  inspect(role, content="\"assistant\"")
  inspect(content.length(), content="1")
}

///|
test "responses/ResponseItem from_json function_call" {
  let json : Json = {
    "type": "function_call",
    "call_id": "c1",
    "name": "get_weather",
    "arguments": "{\"city\":\"NYC\"}",
  }
  let item : ResponseItem = @json.from_json(json)
  guard item is ResponseItem::FunctionCall(call_id~, name~, arguments~) else {
    fail("expected FunctionCall")
  }
  inspect(call_id, content="\"c1\"")
  inspect(name, content="\"get_weather\"")
  inspect(arguments, content="\"{\\\"city\\\":\\\"NYC\\\"}\"")
}

///|
test "responses/ResponseItem from_json unknown type" {
  let json : Json = { "type": "unknown_type" }
  try {
    let _ : ResponseItem = @json.from_json(json)
    fail("expected error")
  } catch {
    _ => ()
  }
}

///|
test "responses/message_input user role" {
  let item = message_input(role="user", content="Hello")
  guard item is ResponseInputItem::Message(role~, content~) else {
    fail("expected Message")
  }
  inspect(role, content="\"user\"")
  debug_inspect(content[0].type_, content="InputText")
  inspect(content[0].text, content="\"Hello\"")
}

///|
test "responses/message_input non-user role" {
  let item = message_input(role="assistant", content="Hi there")
  guard item is ResponseInputItem::Message(content~, ..) else {
    fail("expected Message")
  }
  debug_inspect(content[0].type_, content="OutputText")
}

///|
test "responses/function_call_output" {
  let item = function_call_output(call_id="c1", output="result data")
  guard item is ResponseInputItem::FunctionCallOutput(call_id~, output~) else {
    fail("expected FunctionCallOutput")
  }
  inspect(call_id, content="\"c1\"")
  inspect(output, content="\"result data\"")
}

///|
test "responses/ResponsesRequest to_json without optional" {
  let req = ResponsesRequest::new(
    model="gpt-4o",
    input=[],
    instructions="Be helpful",
  )
  let json = req.to_json()
  json_inspect(
    json,
    content="{\"model\":\"gpt-4o\",\"input\":[],\"instructions\":\"Be helpful\",\"tools\":[],\"tool_choice\":\"auto\"}",
  )
}

///|
test "responses/ResponsesRequest to_json with optional" {
  let req = ResponsesRequest::new(
    model="gpt-4o",
    input=[],
    instructions="Be helpful",
    stream=true,
    store=false,
  )
  let json = req.to_json()
  json_inspect(
    json,
    content="{\"model\":\"gpt-4o\",\"input\":[],\"instructions\":\"Be helpful\",\"tools\":[],\"tool_choice\":\"auto\",\"stream\":true,\"store\":false}",
  )
}
