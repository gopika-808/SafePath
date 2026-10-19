package com.safepath.exception;

/** TEMPORARY COPY from contract Section 9. Delete this when Backend pushes the real one. */
public class SafePathException extends Exception {
    public SafePathException(String msg) { super(msg); }
    public SafePathException(String msg, Throwable cause) { super(msg, cause); }
}
