package com.moonbit.maria;

/**
 * Sealed interface representing Server-Sent Events from the Maria server.
 */
public sealed interface ServerStreamEvent
        permits ServerStreamEvent.MariaQueuedMessagesSynchronized,
                ServerStreamEvent.Maria {

    record MariaQueuedMessagesSynchronized(QueuedMessage[] queued_messages)
            implements ServerStreamEvent {
    }

    record Maria(Event event) implements ServerStreamEvent {
    }

    /**
     * Simplified queued message record.
     */
    record QueuedMessage(String id, Object message) {
    }

    /**
     * Simplified event record.
     */
    record Event(String id, long created, Object desc) {
    }
}