///|
test "CreateMessageResponse::to_json_from_json" {
  let msg_id = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let response = CreateMessageResponse::{
    success: true,
    id: msg_id,
    queued: false,
  }
  let json = response.to_json()
  let roundtripped : CreateMessageResponse = @json.from_json(json)
  inspect(roundtripped.success, content="true")
  inspect(roundtripped.id == msg_id, content="true")
  inspect(roundtripped.queued, content="false")
}

///|
test "CreateMessageResponse::to_json_format" {
  let msg_id = @uuid.parse("72212911-64d1-c441-e87d-de89b955ea34")
  let response = CreateMessageResponse::{
    success: true,
    id: msg_id,
    queued: false,
  }
  json_inspect(response.to_json(), content={
    "success": true,
    "id": "72212911-64d1-c441-e87d-de89b955ea34",
    "queued": false,
  })
}

///|
test "CreateMessageResponse::from_json_error" {
  let missing_field : Json = {
    "success": true,
    "id": "72212911-64d1-c441-e87d-de89b955ea34",
  }
  try {
    let _ : CreateMessageResponse = @json.from_json(missing_field)
    fail("expected from_json to raise on missing field")
  } catch {
    @json.JsonDecodeError(_) => ()
    _ => fail("expected JsonDecodeError, got other error")
  }
  let non_object : Json = 42.0
  try {
    let _ : CreateMessageResponse = @json.from_json(non_object)
    fail("expected from_json to raise on non-object")
  } catch {
    @json.JsonDecodeError(_) => ()
    _ => fail("expected JsonDecodeError, got other error")
  }
}
