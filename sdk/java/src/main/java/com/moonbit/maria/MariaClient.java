package com.moonbit.maria;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Flow;
import java.util.concurrent.SubmissionPublisher;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.reflect.TypeToken;

/**
 * HTTP client for the multi-session Maria server API.
 *
 * <p>
 * Example usage:
 * </p>
 *
 * <pre>
 * MariaClient client = new MariaClient("http://localhost:8080");
 * Map&lt;String, String&gt; result = client.createSession(new CreateSessionOpts());
 * String sessionId = result.get("session_id");
 * client.sendMessage(sessionId, Map.of("role", "user", "content", "Hello"), null);
 * </pre>
 */
public class MariaClient {

    private static final Gson gson = new GsonBuilder().create();
    private final String baseUrl;
    private final HttpClient httpClient;

    /**
     * Creates a new MariaClient with the given base URL.
     *
     * @param baseUrl The base URL of the Maria server (e.g. "http://localhost:8080")
     */
    public MariaClient(String baseUrl) {
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    /**
     * Creates a new session.
     *
     * @param opts Create session options (name, resume_id, web_search)
     * @return A map containing "session_id" and "agent_id"
     * @throws IOException  If the request fails
     * @throws InterruptedException If the request is interrupted
     */
    public Map<String, String> createSession(CreateSessionOpts opts)
            throws IOException, InterruptedException, MariaHttpException {
        String body = gson.toJson(opts);
        HttpResponse<String> response = sendRequest("POST", "/v1/sessions", body);
        return gson.fromJson(response.body(), new TypeToken<Map<String, String>>(){}.getType());
    }

    /**
     * Lists all sessions.
     *
     * @return A list of session info objects
     * @throws IOException  If the request fails
     * @throws InterruptedException If the request is interrupted
     */
    public List<Session> listSessions() throws IOException, InterruptedException, MariaHttpException {
        HttpResponse<String> response = sendRequest("GET", "/v1/sessions", null);
        return gson.fromJson(response.body(), new TypeToken<List<Session>>(){}.getType());
    }

    /**
     * Gets a single session by ID.
     *
     * @param sessionId The session ID
     * @return The session info, or empty if not found
     * @throws IOException  If the request fails
     * @throws InterruptedException If the request is interrupted
     */
    public Optional<Session> getSession(String sessionId)
            throws IOException, InterruptedException, MariaHttpException {
        try {
            HttpResponse<String> response = sendRequest("GET", "/v1/sessions/" + sessionId, null);
            return Optional.of(gson.fromJson(response.body(), Session.class));
        } catch (MariaHttpException e) {
            if (e.getStatusCode() == 404) {
                return Optional.empty();
            }
            throw e;
        }
    }

    /**
     * Closes a session by ID.
     *
     * @param sessionId The session ID
     * @return true if the session was closed, false if not found
     * @throws IOException  If the request fails
     * @throws InterruptedException If the request is interrupted
     */
    public boolean closeSession(String sessionId)
            throws IOException, InterruptedException, MariaHttpException {
        try {
            sendRequest("DELETE", "/v1/sessions/" + sessionId, null);
            return true;
        } catch (MariaHttpException e) {
            if (e.getStatusCode() == 404) {
                return false;
            }
            throw e;
        }
    }

    /**
     * Sends a message to a session.
     *
     * @param sessionId The session ID
     * @param message   The message object (role + content)
     * @param webSearch Optional web search flag
     * @return A map containing the success status
     * @throws IOException  If the request fails
     * @throws InterruptedException If the request is interrupted
     */
    public Map<String, Object> sendMessage(String sessionId, Map<String, Object> message, Boolean webSearch)
            throws IOException, InterruptedException, MariaHttpException {
        JsonObject obj = new JsonObject();
        obj.add("message", gson.toJsonTree(message));
        if (webSearch != null) {
            obj.addProperty("web_search", webSearch);
        }
        HttpResponse<String> response = sendRequest("POST", "/v1/sessions/" + sessionId + "/message", obj.toString());
        return gson.fromJson(response.body(), new TypeToken<Map<String, Object>>(){}.getType());
    }

    /**
     * Streams Server-Sent Events for a session.
     *
     * @param sessionId The session ID
     * @return A SubmissionPublisher that emits ServerStreamEvent objects
     */
    public SubmissionPublisher<ServerStreamEvent> streamEvents(String sessionId) {
        SubmissionPublisher<ServerStreamEvent> publisher = new SubmissionPublisher<>();
        String url = baseUrl + "/v1/sessions/" + sessionId + "/events";

        httpClient.sendAsync(
                HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .header("Accept", "text/event-stream")
                        .GET()
                        .build(),
                HttpResponse.BodyHandlers.ofLines()
        ).thenAccept(response -> {
            response.body().forEach(line -> {
                if (line.startsWith("data:")) {
                    String data = line.substring(5).trim();
                    try {
                        JsonElement element = gson.fromJson(data, JsonElement.class);
                        if (element.isJsonArray()) {
                            ServerStreamEvent.QueuedMessage[] msgs = gson.fromJson(
                                    element,
                                    ServerStreamEvent.QueuedMessage[].class
                            );
                            publisher.submit(new ServerStreamEvent.MariaQueuedMessagesSynchronized(msgs));
                        } else {
                            ServerStreamEvent.Event event = gson.fromJson(element, ServerStreamEvent.Event.class);
                            publisher.submit(new ServerStreamEvent.Maria(event));
                        }
                    } catch (Exception e) {
                        publisher.closeExceptionally(e);
                    }
                }
            });
            publisher.close();
        });

        return publisher;
    }

    private HttpResponse<String> sendRequest(String method, String path, String body)
            throws IOException, InterruptedException, MariaHttpException {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + path));
        if (body != null) {
            builder.header("Content-Type", "application/json")
                    .method(method, HttpRequest.BodyPublishers.ofString(body));
        } else {
            builder.method(method, HttpRequest.BodyPublishers.noBody());
        }
        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        int statusCode = response.statusCode();
        if (statusCode < 200 || statusCode >= 300) {
            throw new MariaHttpException(statusCode, response.body());
        }
        return response;
    }

    /**
     * Options for creating a session.
     */
    public static class CreateSessionOpts {
        public String name;
        public String resume_id;
        public Boolean web_search;

        public CreateSessionOpts name(String name) {
            this.name = name;
            return this;
        }

        public CreateSessionOpts resumeId(String resumeId) {
            this.resume_id = resumeId;
            return this;
        }

        public CreateSessionOpts webSearch(Boolean webSearch) {
            this.web_search = webSearch;
            return this;
        }
    }
}