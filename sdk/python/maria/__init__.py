import importlib.resources as resources
import asyncio
import codecs
import json
import platform
import urllib.request
import urllib.error
from dataclasses import dataclass
from typing import AsyncGenerator, Optional, List, Dict, Any, Union
import maria.events


def _get_system() -> str:
    return f"{platform.system().lower()}-{platform.machine().lower()}"


class Maria:
    async def start(
        self, prompt: str
    ) -> AsyncGenerator[maria.events.Notification, None]:
        system = _get_system()
        resource = resources.files("maria").joinpath("bin").joinpath(f"{system}.exe")
        with resources.as_file(resource) as executable_path:
            process = await asyncio.create_subprocess_exec(
                executable_path,
                "exec",
                prompt,
                stdout=asyncio.subprocess.PIPE,
            )
            assert process.stdout is not None

            # Read stdout asynchronously line by line
            while True:
                line = await process.stdout.readline()
                if not line:
                    break
                yield maria.events.notification.validate_json(line)

            status = await process.wait()
            if status != 0:
                raise RuntimeError(f"Maria process failed to start: {status}")


class HTTPResponseError(Exception):
    """Raised when the server returns a non-2xx HTTP status code."""

    def __init__(self, status_code: int, body: str):
        self.status_code = status_code
        self.body = body
        super().__init__(f"HTTP {status_code}: {body}")


@dataclass
class MariaQueuedMessagesSynchronized:
    queued_messages: List[Dict[str, Any]]


@dataclass
class MariaEvent:
    event: Dict[str, Any]


ServerStreamEvent = Union[MariaQueuedMessagesSynchronized, MariaEvent]


class MariaClient:
    """HTTP client for the multi-session Maria server API."""

    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")

    def _request(
        self,
        method: str,
        path: str,
        body: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        url = f"{self.base_url}{path}"
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={"Content-Type": "application/json"} if data else {},
        )
        try:
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            payload = e.read().decode("utf-8")
            raise HTTPResponseError(e.code, payload)

    def create_session(
        self,
        name: Optional[str] = None,
        resume_id: Optional[str] = None,
        web_search: Optional[bool] = None,
    ) -> Dict[str, str]:
        body: Dict[str, Any] = {}
        if name is not None:
            body["name"] = name
        if resume_id is not None:
            body["resume_id"] = resume_id
        if web_search is not None:
            body["web_search"] = web_search
        return self._request("POST", "/v1/sessions", body)

    def list_sessions(self) -> List[Dict[str, Any]]:
        return self._request("GET", "/v1/sessions")

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        try:
            return self._request("GET", f"/v1/sessions/{session_id}")
        except HTTPResponseError as e:
            if e.status_code == 404:
                return None
            raise

    def close_session(self, session_id: str) -> bool:
        try:
            self._request("DELETE", f"/v1/sessions/{session_id}")
            return True
        except HTTPResponseError as e:
            if e.status_code == 404:
                return False
            raise

    def send_message(
        self,
        session_id: str,
        message: Dict[str, Any],
        web_search: Optional[bool] = None,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {"message": message}
        if web_search is not None:
            body["web_search"] = web_search
        return self._request("POST", f"/v1/sessions/{session_id}/message", body)

    async def stream_events(
        self, session_id: str
    ) -> AsyncGenerator[ServerStreamEvent, None]:
        url = f"{self.base_url}/v1/sessions/{session_id}/events"
        req = urllib.request.Request(url, method="GET")
        try:
            resp = await asyncio.to_thread(urllib.request.urlopen, req)
        except urllib.error.HTTPError as e:
            payload = e.read().decode("utf-8")
            raise HTTPResponseError(e.code, payload)
        try:
            decoder = codecs.getincrementaldecoder("utf-8")()
            buffer = ""
            while True:
                chunk = await asyncio.to_thread(resp.read, 4096)
                if not chunk:
                    decoder.decode(b"", final=True)
                    break
                buffer += decoder.decode(chunk)
                while "\n\n" in buffer:
                    event_block, buffer = buffer.split("\n\n", 1)
                    event_data = ""
                    for line in event_block.split("\n"):
                        if line.startswith("data:"):
                            event_data += line[5:].strip()
                    if event_data:
                        parsed = json.loads(event_data)
                        if isinstance(parsed, list):
                            yield MariaQueuedMessagesSynchronized(queued_messages=parsed)
                        else:
                            yield MariaEvent(event=parsed)
        finally:
            resp.close()
