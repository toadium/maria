///|
/// R18 SimpleTeam 集成测试。
/// 验证 SimpleTeam 与 AgentRouter（MockRouter）的协作：
/// add_member/remove_member/broadcast 通过 router.route 投递消息。

///|
async test "agent/simple_team_construct_empty" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  inspect(team.members().length(), content="0")
}

///|
async test "agent/simple_team_add_member_dedup" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let id1 = @agentid.nil
  team.add_member(id1)
  team.add_member(id1)
  inspect(team.members().length(), content="1")
}

///|
async test "agent/simple_team_remove_member" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let id1 = @agentid.nil
  team.add_member(id1)
  team.remove_member(id1)
  inspect(team.members().length(), content="0")
}

///|
async test "agent/simple_team_remove_nonexistent_member" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let id1 = @agentid.nil
  team.remove_member(id1)
  inspect(team.members().length(), content="0")
}

///|
async test "agent/simple_team_broadcast_routes_to_all_members" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let id1 = @agentid.nil
  let id2 = @agentid.nil
  team.add_member(id1)
  team.add_member(id2)
  let message = @ai.user_message(content="broadcast")
  let f = AgentTeam::broadcast(team, message)
  f(())
  inspect(mock.routed.length(), content="2")
}

///|
async test "agent/simple_team_broadcast_empty_team_noop" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let message = @ai.user_message(content="broadcast")
  let f = AgentTeam::broadcast(team, message)
  f(())
  inspect(mock.routed.length(), content="0")
}

///|
async test "agent/simple_team_members_returns_copy" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let id1 = @agentid.nil
  team.add_member(id1)
  let members1 = team.members()
  let members2 = team.members()
  inspect(members1.length(), content="1")
  inspect(members2.length(), content="1")
  members1.push(@agentid.nil)
  inspect(members1.length(), content="2")
  inspect(members2.length(), content="1")
}

///|
async test "agent/simple_team_trait_object_storable" {
  let mock = MockRouter::new()
  let team = SimpleTeam::new(router=mock)
  let team_trait : &AgentTeam = team
  let id1 = @agentid.nil
  AgentTeam::add_member(team_trait, id1)
  inspect(AgentTeam::members(team_trait).length(), content="1")
  let message = @ai.user_message(content="via_trait")
  let f = AgentTeam::broadcast(team_trait, message)
  f(())
  inspect(mock.routed.length(), content="1")
}
