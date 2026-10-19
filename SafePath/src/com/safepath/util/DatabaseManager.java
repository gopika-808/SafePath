package com.safepath.util;

import com.safepath.exception.DatabaseException;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/** Singleton that hands out JDBC connections. Reads db/db.properties from the project folder. */
public class DatabaseManager {

    private static DatabaseManager instance;
    private final String url;
    private final String user;
    private final String password;

    private DatabaseManager() throws DatabaseException {
        Properties props = new Properties();
        try (FileInputStream in = new FileInputStream("db/db.properties")) {
            props.load(in);
        } catch (IOException e) {
            throw new DatabaseException("Cannot read db/db.properties. Run the program from the project folder.", e);
        }
        this.url = props.getProperty("db.url");
        this.user = props.getProperty("db.user");
        this.password = props.getProperty("db.password");
        String driver = props.getProperty("db.driver");
        try {
            Class.forName(driver);
        } catch (ClassNotFoundException e) {
            throw new DatabaseException("JDBC driver not found. Add the jar in lib/ to the classpath.", e);
        }
    }

    public static synchronized DatabaseManager getInstance() throws DatabaseException {
        if (instance == null) {
            instance = new DatabaseManager();
        }
        return instance;
    }

    /** Every caller gets a NEW connection and must close it (use try-with-resources). */
    public Connection getConnection() throws DatabaseException {
        try {
            return DriverManager.getConnection(url, user, password);
        } catch (SQLException e) {
            throw new DatabaseException("Could not connect to the database: " + e.getMessage(), e);
        }
    }

    public void close() {
        instance = null; // connections are per-call, nothing else to release
    }
}
