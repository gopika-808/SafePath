package com.safepath.util;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

/** Throwaway test: run it to check the DB connection and seed data. Not part of the final app. */
public class DbTest {
    public static void main(String[] args) {
        try (Connection c = DatabaseManager.getInstance().getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT route_id, name FROM routes")) {
            System.out.println("Connected!");
            while (rs.next()) {
                System.out.println(rs.getInt("route_id") + " - " + rs.getString("name"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
