package com.moonbit.maria;

import java.util.Objects;
import com.google.gson.annotations.SerializedName;

/**
 * Represents a session in the multi-session Maria server.
 */
public class Session {
    private String id;
    @SerializedName("agent_id")
    private String agentId;
    private boolean busy;
    @SerializedName("created_at")
    private long createdAt;
    @SerializedName("last_active")
    private long lastActive;

    public String getId() {
        return id;
    }

    public String getAgentId() {
        return agentId;
    }

    public boolean isBusy() {
        return busy;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public long getLastActive() {
        return lastActive;
    }

    @Override
    public String toString() {
        return "Session{id='" + id + "', agentId='" + agentId + "', busy=" + busy
                + ", createdAt=" + createdAt + ", lastActive=" + lastActive + "}";
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Session session = (Session) o;
        return busy == session.busy
                && createdAt == session.createdAt
                && lastActive == session.lastActive
                && Objects.equals(id, session.id)
                && Objects.equals(agentId, session.agentId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, agentId, busy, createdAt, lastActive);
    }
}