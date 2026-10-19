package com.safepath.exception;

/** TEMPORARY COPY from contract Section 9. Delete this when Backend pushes the real one. */
public class DatabaseException extends SafePathException {
    public DatabaseException(String msg) { super(msg); }
    public DatabaseException(String msg, Throwable cause) { super(msg, cause); }
}
