package com.moonbit.maria;

/**
 * Thrown when the Maria server returns a non-2xx HTTP status code.
 */
public class MariaHttpException extends Exception {

    private final int statusCode;
    private final String body;

    public MariaHttpException(int statusCode, String body) {
        super("HTTP " + statusCode + ": " + body);
        this.statusCode = statusCode;
        this.body = body;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public String getBody() {
        return body;
    }
}
