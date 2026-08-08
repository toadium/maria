///|
/// 验证 trait object 引用形式 &Trait + 显式 trait 方法调用语法
pub(all) struct ProbeAgent {
  tracer : &@trace.Tracer
  registry : @component.ComponentRegistry
  agent_id : @agentid.AgentId
  trace_enabled : Bool
}

///|
pub fn ProbeAgent::new(uuid : @uuid.Generator) -> ProbeAgent {
  ProbeAgent::{
    tracer: @trace.NoopTracer::new(),
    registry: @component.ComponentRegistry::new(),
    agent_id: @agentid.AgentId::from_uuid(uuid.v4()),
    trace_enabled: false,
  }
}

///|
pub fn ProbeAgent::start_span(self : ProbeAgent) -> @trace.Span {
  @trace.Tracer::start_span(
    self.tracer,
    name="probe",
    kind=@trace.Session,
    parent=None,
  )
}

///|
pub fn ProbeAgent::end_span(self : ProbeAgent, span : @trace.Span) -> Unit {
  @trace.Tracer::end_span(self.tracer, span, status=@trace.Ok)
}
